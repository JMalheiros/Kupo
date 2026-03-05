# Hugo Publish Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** When an article is published in KUPO, automatically format it as a Hugo blog post and push it to a GitHub Pages repo.

**Architecture:** A background job (`HugoPublishJob`) is enqueued after `publish_now!`. It uses `HugoPostFormatter` to generate front matter and rewrite image URLs, then `HugoGitClient` to clone the Hugo repo via SSH deploy key, commit the post bundle, and push to main.

**Tech Stack:** Ruby on Rails, Solid Queue, ActiveStorage, Git (shell), SSH deploy keys

**Design doc:** `docs/plans/2026-03-05-hugo-publish-design.md`

---

### Task 1: HugoPostFormatter - Front Matter Generation

**Files:**
- Create: `app/services/hugo_post_formatter.rb`
- Create: `test/services/hugo_post_formatter_test.rb`

**Step 1: Write the failing test for front matter generation**

```ruby
# test/services/hugo_post_formatter_test.rb
require "test_helper"

class HugoPostFormatterTest < ActiveSupport::TestCase
  context "#format" do
    should "generate Hugo front matter with title, date, categories, and draft false" do
      tech = create(:category, name: "Tech")
      rails = create(:category, name: "Rails")
      article = create(:article, :published,
        title: "My Article",
        body: "Some content here.",
        published_at: Time.zone.parse("2026-03-05 14:30:00"))
      article.categories << [tech, rails]

      result = HugoPostFormatter.new(article).format

      assert_match "---\n", result
      assert_match 'title: "My Article"', result
      assert_match "date: 2026-03-05T", result
      assert_match 'categories: ["Tech", "Rails"]', result
      assert_match "draft: false", result
      assert_match "---\n\nSome content here.", result
    end
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bin/rails test test/services/hugo_post_formatter_test.rb`
Expected: FAIL — `NameError: uninitialized constant HugoPostFormatter`

**Step 3: Write minimal implementation**

```ruby
# app/services/hugo_post_formatter.rb
class HugoPostFormatter
  def initialize(article)
    @article = article
  end

  def format
    "#{front_matter}#{body}"
  end

  private

  def front_matter
    <<~YAML
      ---
      title: "#{@article.title}"
      date: #{@article.published_at.iso8601}
      categories: #{@article.categories.pluck(:name).inspect}
      draft: false
      ---

    YAML
  end

  def body
    @article.body
  end
end
```

**Step 4: Run test to verify it passes**

Run: `bin/rails test test/services/hugo_post_formatter_test.rb`
Expected: PASS

**Step 5: Commit**

```bash
git add app/services/hugo_post_formatter.rb test/services/hugo_post_formatter_test.rb
git commit -m "Add HugoPostFormatter with front matter generation"
```

---

### Task 2: HugoPostFormatter - Image URL Rewriting

**Files:**
- Modify: `app/services/hugo_post_formatter.rb`
- Modify: `test/services/hugo_post_formatter_test.rb`

**Step 1: Write the failing test for image URL rewriting**

Add to `test/services/hugo_post_formatter_test.rb`:

```ruby
should "rewrite ActiveStorage image URLs to relative paths" do
  article = create(:article, :published,
    title: "Image Post",
    body: "Hello\n\n![photo.png](/rails/active_storage/blobs/redirect/abc123/photo.png)\n\nMore text\n\n![diagram.jpg](/rails/active_storage/blobs/redirect/def456/diagram.jpg)")

  result = HugoPostFormatter.new(article).format

  assert_match "![photo.png](photo.png)", result
  assert_match "![diagram.jpg](diagram.jpg)", result
  refute_match "/rails/active_storage", result
end

should "leave body unchanged when there are no images" do
  article = create(:article, :published, title: "No Images", body: "Just text.")

  result = HugoPostFormatter.new(article).format

  assert_match "Just text.", result
end
```

**Step 2: Run test to verify it fails**

Run: `bin/rails test test/services/hugo_post_formatter_test.rb`
Expected: FAIL — ActiveStorage URLs still present in output

**Step 3: Add image URL rewriting to the formatter**

Add to `hugo_post_formatter.rb`, replace the `body` method:

```ruby
IMAGE_PATTERN = /!\[([^\]]*)\]\(\/rails\/active_storage\/blobs\/redirect\/[^\/]+\/([^)]+)\)/

def body
  @article.body.gsub(IMAGE_PATTERN) do |_match|
    alt = Regexp.last_match(1)
    filename = Regexp.last_match(2)
    "![#{alt}](#{filename})"
  end
end

def image_references
  @article.body.scan(IMAGE_PATTERN).map do |alt, filename|
    { alt: alt, filename: filename }
  end
end
```

Make `image_references` public (move above `private`).

**Step 4: Run test to verify it passes**

Run: `bin/rails test test/services/hugo_post_formatter_test.rb`
Expected: PASS

**Step 5: Commit**

```bash
git add app/services/hugo_post_formatter.rb test/services/hugo_post_formatter_test.rb
git commit -m "Add image URL rewriting to HugoPostFormatter"
```

---

### Task 3: HugoPostFormatter - Extract Image References

**Files:**
- Modify: `test/services/hugo_post_formatter_test.rb`

**Step 1: Write the failing test for image_references**

Add to `test/services/hugo_post_formatter_test.rb`:

```ruby
context "#image_references" do
  should "return list of image filenames and signed IDs from body" do
    article = create(:article, :published,
      title: "Image Post",
      body: "![photo.png](/rails/active_storage/blobs/redirect/abc123/photo.png)\n![diagram.jpg](/rails/active_storage/blobs/redirect/def456/diagram.jpg)")

    refs = HugoPostFormatter.new(article).image_references

    assert_equal 2, refs.length
    assert_equal({ alt: "photo.png", filename: "photo.png" }, refs[0])
    assert_equal({ alt: "diagram.jpg", filename: "diagram.jpg" }, refs[1])
  end

  should "return empty array when no images" do
    article = create(:article, :published, body: "No images here.")

    refs = HugoPostFormatter.new(article).image_references

    assert_empty refs
  end
end
```

**Step 2: Run test to verify it passes (already implemented in Task 2)**

Run: `bin/rails test test/services/hugo_post_formatter_test.rb`
Expected: PASS (if `image_references` was made public in Task 2)

**Step 3: Update image_references to also return signed_id**

Update the regex capture and method to include signed_id:

```ruby
IMAGE_PATTERN = /!\[([^\]]*)\]\(\/rails\/active_storage\/blobs\/redirect\/([^\/]+)\/([^)]+)\)/

def body
  @article.body.gsub(IMAGE_PATTERN) do |_match|
    alt = Regexp.last_match(1)
    filename = Regexp.last_match(3)
    "![#{alt}](#{filename})"
  end
end

def image_references
  @article.body.scan(IMAGE_PATTERN).map do |alt, signed_id, filename|
    { alt: alt, signed_id: signed_id, filename: filename }
  end
end
```

Update the test assertions to include `signed_id`:

```ruby
assert_equal({ alt: "photo.png", signed_id: "abc123", filename: "photo.png" }, refs[0])
assert_equal({ alt: "diagram.jpg", signed_id: "def456", filename: "diagram.jpg" }, refs[1])
```

**Step 4: Run tests**

Run: `bin/rails test test/services/hugo_post_formatter_test.rb`
Expected: PASS

**Step 5: Commit**

```bash
git add app/services/hugo_post_formatter.rb test/services/hugo_post_formatter_test.rb
git commit -m "Extract signed_id from image references in HugoPostFormatter"
```

---

### Task 4: HugoGitClient

**Files:**
- Create: `app/services/hugo_git_client.rb`
- Create: `test/services/hugo_git_client_test.rb`

**Step 1: Write the failing test**

```ruby
# test/services/hugo_git_client_test.rb
require "test_helper"

class HugoGitClientTest < ActiveSupport::TestCase
  setup do
    @tmp_dir = Dir.mktmpdir
    @repo_url = "git@github.com:user/blog.git"
    @deploy_key_path = "/tmp/test_deploy_key"
  end

  teardown do
    FileUtils.rm_rf(@tmp_dir)
  end

  context "#clone" do
    should "run git clone with SSH deploy key" do
      client = HugoGitClient.new(repo_url: @repo_url, deploy_key_path: @deploy_key_path, work_dir: @tmp_dir)

      command_run = nil
      client.stub(:run_git, ->(cmd) { command_run = cmd; true }) do
        client.clone
      end

      assert_match "GIT_SSH_COMMAND", command_run
      assert_match @deploy_key_path, command_run
      assert_match "git clone", command_run
      assert_match @repo_url, command_run
    end
  end

  context "#commit_and_push" do
    should "run git add, commit, and push" do
      client = HugoGitClient.new(repo_url: @repo_url, deploy_key_path: @deploy_key_path, work_dir: @tmp_dir)

      commands_run = []
      client.stub(:run_git, ->(cmd) { commands_run << cmd; true }) do
        client.commit_and_push("Add post: my-article")
      end

      assert commands_run.any? { |c| c.include?("git add") }
      assert commands_run.any? { |c| c.include?("git commit") && c.include?("Add post: my-article") }
      assert commands_run.any? { |c| c.include?("git push") }
    end
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bin/rails test test/services/hugo_git_client_test.rb`
Expected: FAIL — `NameError: uninitialized constant HugoGitClient`

**Step 3: Implement HugoGitClient**

```ruby
# app/services/hugo_git_client.rb
class HugoGitClient
  def initialize(repo_url:, deploy_key_path:, work_dir:)
    @repo_url = repo_url
    @deploy_key_path = deploy_key_path
    @work_dir = work_dir
  end

  def clone
    run_git("GIT_SSH_COMMAND='ssh -i #{@deploy_key_path} -o StrictHostKeyChecking=accept-new' git clone --depth 1 #{@repo_url} #{@work_dir}/repo")
  end

  def commit_and_push(message)
    run_git("git -C #{repo_path} add -A")
    run_git("git -C #{repo_path} commit -m '#{message}'")
    run_git("GIT_SSH_COMMAND='ssh -i #{@deploy_key_path} -o StrictHostKeyChecking=accept-new' git -C #{repo_path} push origin main")
  end

  def repo_path
    "#{@work_dir}/repo"
  end

  private

  def run_git(command)
    system(command, exception: true)
  end
end
```

**Step 4: Run test to verify it passes**

Run: `bin/rails test test/services/hugo_git_client_test.rb`
Expected: PASS

**Step 5: Commit**

```bash
git add app/services/hugo_git_client.rb test/services/hugo_git_client_test.rb
git commit -m "Add HugoGitClient for SSH-based git operations"
```

---

### Task 5: HugoPublishJob

**Files:**
- Create: `app/jobs/hugo_publish_job.rb`
- Create: `test/jobs/hugo_publish_job_test.rb`

**Step 1: Write the failing test**

```ruby
# test/jobs/hugo_publish_job_test.rb
require "test_helper"

class HugoPublishJobTest < ActiveSupport::TestCase
  context "perform" do
    should "format article, clone repo, write post, copy images, commit and push" do
      article = create(:article, :published, title: "My Post", slug: "my-post", body: "Hello world.")

      formatter = Minitest::Mock.new
      formatter.expect(:format, "---\ntitle: \"My Post\"\n---\n\nHello world.")
      formatter.expect(:image_references, [])

      git_client = Minitest::Mock.new
      git_client.expect(:clone, true)
      git_client.expect(:repo_path, "/tmp/test/repo")
      git_client.expect(:commit_and_push, true, ["Add post: my-post"])

      HugoPostFormatter.stub(:new, formatter) do
        HugoGitClient.stub(:new, git_client) do
          Dir.stub(:mktmpdir, "/tmp/test") do
            FileUtils.stub(:mkdir_p, true) do
              File.stub(:write, true) do
                FileUtils.stub(:rm_rf, true) do
                  HugoPublishJob.perform_now(article)
                end
              end
            end
          end
        end
      end

      formatter.verify
      git_client.verify
    end

    should "skip if HUGO_REPO_SSH_URL is not configured" do
      article = create(:article, :published)

      ENV.stub(:fetch, ->(_k, _d) { nil }) do
        # Should not raise, just return early
        HugoPublishJob.perform_now(article)
      end
    end
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bin/rails test test/jobs/hugo_publish_job_test.rb`
Expected: FAIL — `NameError: uninitialized constant HugoPublishJob`

**Step 3: Implement HugoPublishJob**

```ruby
# app/jobs/hugo_publish_job.rb
class HugoPublishJob < ApplicationJob
  queue_as :default

  def perform(article)
    repo_url = ENV.fetch("HUGO_REPO_SSH_URL", nil)
    deploy_key_path = ENV.fetch("HUGO_DEPLOY_KEY_PATH", nil)
    return unless repo_url.present? && deploy_key_path.present?

    tmp_dir = Dir.mktmpdir("hugo-publish")

    begin
      git_client = HugoGitClient.new(repo_url: repo_url, deploy_key_path: deploy_key_path, work_dir: tmp_dir)
      git_client.clone

      formatter = HugoPostFormatter.new(article)
      post_dir = File.join(git_client.repo_path, "content", "posts", article.slug)
      FileUtils.mkdir_p(post_dir)

      File.write(File.join(post_dir, "index.md"), formatter.format)

      copy_images(formatter.image_references, post_dir)

      git_client.commit_and_push("Add post: #{article.slug}")
    ensure
      FileUtils.rm_rf(tmp_dir)
    end
  end

  private

  def copy_images(image_references, post_dir)
    image_references.each do |ref|
      blob = ActiveStorage::Blob.find_signed(ref[:signed_id])
      next unless blob

      blob.open do |tempfile|
        FileUtils.cp(tempfile.path, File.join(post_dir, ref[:filename]))
      end
    rescue => e
      Rails.logger.warn("Hugo publish: failed to copy image #{ref[:filename]}: #{e.message}")
    end
  end
end
```

**Step 4: Run test to verify it passes**

Run: `bin/rails test test/jobs/hugo_publish_job_test.rb`
Expected: PASS

**Step 5: Commit**

```bash
git add app/jobs/hugo_publish_job.rb test/jobs/hugo_publish_job_test.rb
git commit -m "Add HugoPublishJob to publish articles to Hugo blog"
```

---

### Task 6: Hook into Article#publish_now!

**Files:**
- Modify: `app/models/article.rb:18-20`
- Modify: `test/jobs/publish_article_job_test.rb`

**Step 1: Write the failing test**

Add to `test/jobs/publish_article_job_test.rb`:

```ruby
should "enqueue HugoPublishJob when publishing a scheduled article" do
  article = create(:article, :scheduled, published_at: 1.minute.ago)

  assert_enqueued_with(job: HugoPublishJob, args: [article]) do
    PublishArticleJob.perform_now(article)
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bin/rails test test/jobs/publish_article_job_test.rb`
Expected: FAIL — `HugoPublishJob` not enqueued

**Step 3: Add HugoPublishJob enqueue to publish_now!**

Modify `app/models/article.rb` line 18-20:

```ruby
def publish_now!
  update!(status: "published", published_at: Time.current)
  HugoPublishJob.perform_later(self)
end
```

**Step 4: Run test to verify it passes**

Run: `bin/rails test test/jobs/publish_article_job_test.rb`
Expected: PASS

**Step 5: Run full test suite**

Run: `bin/rails test`
Expected: All tests pass

**Step 6: Commit**

```bash
git add app/models/article.rb test/jobs/publish_article_job_test.rb
git commit -m "Enqueue HugoPublishJob when article is published"
```

---

### Task 7: Lint and Final Verification

**Step 1: Run RuboCop**

Run: `bundle exec rubocop app/services/hugo_post_formatter.rb app/services/hugo_git_client.rb app/jobs/hugo_publish_job.rb app/models/article.rb`
Expected: No offenses. Fix any that appear.

**Step 2: Run Brakeman**

Run: `bundle exec brakeman --no-pager --quiet`
Expected: No new warnings. If command injection warnings appear for `system()` in HugoGitClient, ensure inputs are from ENV vars only (not user input).

**Step 3: Run full test suite**

Run: `bin/rails test`
Expected: All tests pass, zero failures

**Step 4: Commit any lint fixes**

```bash
git add -A
git commit -m "Fix lint offenses in Hugo publish feature"
```
