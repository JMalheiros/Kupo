# Hugo Publish Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** When an article is published in KUPO, push it to a Hugo GitHub Pages repo as a page bundle, with a `publishing` status and toast notifications via Turbo Stream broadcasts.

**Architecture:** `publish_now!` sets status to `"publishing"` and enqueues `PublishArticleJob`. The job uses `HugoPostFormatter` (front matter + image URL rewriting) and `HugoGitClient` (SSH clone/commit/push) to publish the post, then sets status to `"published"` and broadcasts a toast notification. If Hugo env vars are missing, it skips the git push and publishes directly.

**Tech Stack:** Rails 8.1, Solid Queue, ActiveStorage, Turbo Streams (Action Cable), Phlex, Git (shell), SSH deploy keys

**Design doc:** `docs/plans/2026-03-06-hugo-publish-design.md`

---

### Task 1: Add `publishing` status to Article model

**Files:**
- Modify: `app/models/article.rb:9`
- Modify: `test/factories/articles.rb`
- Modify: `app/views/admin/articles/article_card.rb:42,61-66`

**Step 1: Update the status validation**

In `app/models/article.rb`, change line 9:

```ruby
validates :status, presence: true, inclusion: { in: %w[draft scheduled publishing published] }
```

**Step 2: Update `publish_now!` to set `publishing` and enqueue the job**

In `app/models/article.rb`, replace the `publish_now!` method (lines 18-20):

```ruby
def publish_now!
  update!(status: "publishing", published_at: Time.current)
  PublishArticleJob.perform_later(self)
end
```

**Step 3: Add factory trait**

In `test/factories/articles.rb`, add after the `:scheduled` trait:

```ruby
trait :publishing do
  status { "publishing" }
  published_at { Time.current }
end
```

**Step 4: Update article card badge and publish button visibility**

In `app/views/admin/articles/article_card.rb`, update the `status_variant` method to handle `publishing`:

```ruby
def status_variant(status)
  case status
  when "published" then :green
  when "scheduled" then :yellow
  when "publishing" then :yellow
  when "draft" then :gray
  end
end
```

Update the publish sheet condition on line 42 to also hide for `publishing`:

```ruby
render Views::Admin::Articles::PublishSheet.new(article: @article) unless %w[published publishing].include?(@article.status)
```

Add a pulsing indicator for publishing status. In the `CardHeader` block, after the Badge, add:

```ruby
Badge(variant: status_variant(@article.status)) do
  if @article.status == "publishing"
    span(class: "animate-pulse") { plain "Publishing" }
  else
    plain @article.status.capitalize
  end
end
```

This replaces the existing Badge line.

**Step 5: Run tests**

Run: `bin/rails test`
Expected: Existing tests should still pass. The `PublishArticleJobTest` "publish a scheduled article" test will need updating in Task 6.

**Step 6: Commit**

```bash
git add app/models/article.rb test/factories/articles.rb app/views/admin/articles/article_card.rb
git commit -m "Add publishing status to Article model with pulsing badge"
```

---

### Task 2: HugoPostFormatter - Front matter and image URL rewriting

**Files:**
- Create: `app/services/hugo_post_formatter.rb`
- Create: `test/services/hugo_post_formatter_test.rb`

**Step 1: Write the failing tests**

Create `test/services/hugo_post_formatter_test.rb`:

```ruby
# frozen_string_literal: true

require "test_helper"

class HugoPostFormatterTest < ActiveSupport::TestCase
  context "#format" do
    should "generate Hugo front matter with title, date, categories, and draft false" do
      tech = create(:category, name: "Tech")
      rails_cat = create(:category, name: "Rails")
      article = create(:article, :published,
        title: "My Article",
        body: "Some content here.",
        published_at: Time.zone.parse("2026-03-05 14:30:00"))
      article.categories << [tech, rails_cat]

      result = HugoPostFormatter.new(article).format

      assert_match "---\n", result
      assert_match 'title: "My Article"', result
      assert_match "date: 2026-03-05T", result
      assert_match "categories:", result
      assert_match "Tech", result
      assert_match "Rails", result
      assert_match "draft: false", result
      assert_match "---\n\nSome content here.", result
    end

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
  end

  context "#image_references" do
    should "return list of image filenames and signed IDs from body" do
      article = create(:article, :published,
        body: "![photo.png](/rails/active_storage/blobs/redirect/abc123/photo.png)\n![diagram.jpg](/rails/active_storage/blobs/redirect/def456/diagram.jpg)")

      refs = HugoPostFormatter.new(article).image_references

      assert_equal 2, refs.length
      assert_equal({ alt: "photo.png", signed_id: "abc123", filename: "photo.png" }, refs[0])
      assert_equal({ alt: "diagram.jpg", signed_id: "def456", filename: "diagram.jpg" }, refs[1])
    end

    should "return empty array when no images" do
      article = create(:article, :published, body: "No images here.")

      refs = HugoPostFormatter.new(article).image_references

      assert_empty refs
    end
  end
end
```

**Step 2: Run tests to verify they fail**

Run: `bin/rails test test/services/hugo_post_formatter_test.rb`
Expected: FAIL — `NameError: uninitialized constant HugoPostFormatter`

**Step 3: Write the implementation**

Create `app/services/hugo_post_formatter.rb`:

```ruby
# frozen_string_literal: true

class HugoPostFormatter
  IMAGE_PATTERN = /!\[([^\]]*)\]\(\/rails\/active_storage\/blobs\/redirect\/([^\/]+)\/([^)]+)\)/

  def initialize(article)
    @article = article
  end

  def format
    "#{front_matter}#{body}"
  end

  def image_references
    @article.body.scan(IMAGE_PATTERN).map do |alt, signed_id, filename|
      { alt: alt, signed_id: signed_id, filename: filename }
    end
  end

  private

  def front_matter
    categories = @article.categories.pluck(:name).map { |n| %("#{n}") }.join(", ")

    <<~YAML
      ---
      title: "#{@article.title}"
      date: #{@article.published_at.iso8601}
      categories: [#{categories}]
      draft: false
      ---

    YAML
  end

  def body
    @article.body.gsub(IMAGE_PATTERN) do |_match|
      alt = Regexp.last_match(1)
      filename = Regexp.last_match(3)
      "![#{alt}](#{filename})"
    end
  end
end
```

**Step 4: Run tests to verify they pass**

Run: `bin/rails test test/services/hugo_post_formatter_test.rb`
Expected: 5 tests, 0 failures.

**Step 5: Run rubocop**

Run: `bundle exec rubocop app/services/hugo_post_formatter.rb test/services/hugo_post_formatter_test.rb`
Expected: No offenses.

**Step 6: Commit**

```bash
git add app/services/hugo_post_formatter.rb test/services/hugo_post_formatter_test.rb
git commit -m "Add HugoPostFormatter with front matter and image URL rewriting"
```

---

### Task 3: HugoGitClient

**Files:**
- Create: `app/services/hugo_git_client.rb`
- Create: `test/services/hugo_git_client_test.rb`

**Step 1: Write the failing tests**

Create `test/services/hugo_git_client_test.rb`:

```ruby
# frozen_string_literal: true

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

      commands_run = []
      client.stub(:run_git, ->(*cmd) { commands_run << cmd.join(" "); true }) do
        client.clone
      end

      assert commands_run.any? { |c| c.include?("clone") && c.include?(@repo_url) }
    end
  end

  context "#commit_and_push" do
    should "run git add, commit, and push" do
      client = HugoGitClient.new(repo_url: @repo_url, deploy_key_path: @deploy_key_path, work_dir: @tmp_dir)

      commands_run = []
      client.stub(:run_git, ->(*cmd) { commands_run << cmd.join(" "); true }) do
        client.commit_and_push("Add post: my-article")
      end

      assert commands_run.any? { |c| c.include?("add") }
      assert commands_run.any? { |c| c.include?("commit") && c.include?("Add post: my-article") }
      assert commands_run.any? { |c| c.include?("push") }
    end
  end
end
```

**Step 2: Run tests to verify they fail**

Run: `bin/rails test test/services/hugo_git_client_test.rb`
Expected: FAIL — `NameError: uninitialized constant HugoGitClient`

**Step 3: Write the implementation**

Create `app/services/hugo_git_client.rb`:

```ruby
# frozen_string_literal: true

class HugoGitClient
  attr_reader :repo_path

  def initialize(repo_url:, deploy_key_path:, work_dir:)
    @repo_url = repo_url
    @deploy_key_path = deploy_key_path
    @work_dir = work_dir
    @repo_path = File.join(work_dir, "repo")
  end

  def clone
    run_git("git", "clone", "--depth", "1", @repo_url, @repo_path,
      env: ssh_env)
  end

  def commit_and_push(message)
    run_git("git", "-C", @repo_path, "add", "-A")
    run_git("git", "-C", @repo_path, "commit", "-m", message)
    run_git("git", "-C", @repo_path, "push", "origin", "main",
      env: ssh_env)
  end

  private

  def ssh_env
    { "GIT_SSH_COMMAND" => "ssh -i #{@deploy_key_path} -o StrictHostKeyChecking=accept-new" }
  end

  def run_git(*cmd, env: {})
    system(env, *cmd, exception: true)
  end
end
```

Note: Uses array-form `system()` to avoid shell injection. The SSH command is the only string interpolation and comes from a file path ENV var.

**Step 4: Run tests to verify they pass**

Run: `bin/rails test test/services/hugo_git_client_test.rb`
Expected: 2 tests, 0 failures.

**Step 5: Run rubocop and brakeman**

Run: `bundle exec rubocop app/services/hugo_git_client.rb test/services/hugo_git_client_test.rb`
Expected: No offenses.

Run: `bundle exec brakeman --no-pager --quiet`
Expected: No warnings (array-form `system` is safe).

**Step 6: Commit**

```bash
git add app/services/hugo_git_client.rb test/services/hugo_git_client_test.rb
git commit -m "Add HugoGitClient for SSH-based git operations"
```

---

### Task 4: Toast notification infrastructure

**Files:**
- Modify: `app/views/layouts/application.html.erb`
- Create: `app/javascript/controllers/toast_controller.js`
- Modify: `config/importmap.rb` (add `@rails/actioncable` if missing)

**Step 1: Add `@rails/actioncable` to importmap**

Check if already pinned. If not:

Run: `bin/importmap pin @rails/actioncable`

**Step 2: Add Turbo Stream subscription and notification container to layout**

In `app/views/layouts/application.html.erb`, add after `<main>` opening tag (line 46), before `<%= yield %>`:

```erb
    <main>
      <% if authenticated? %>
        <%= turbo_stream_from Current.user %>
      <% end %>

      <div id="notifications" class="fixed top-4 right-4 z-50 flex flex-col gap-2 w-80"></div>

      <%= yield %>
    </main>
```

**Step 3: Create toast Stimulus controller for auto-dismiss**

Create `app/javascript/controllers/toast_controller.js`:

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { duration: { type: Number, default: 5000 } }

  connect() {
    this.element.classList.add("animate-in", "fade-in", "slide-in-from-right")
    this.timeout = setTimeout(() => this.dismiss(), this.durationValue)
  }

  disconnect() {
    if (this.timeout) clearTimeout(this.timeout)
  }

  dismiss() {
    this.element.classList.add("animate-out", "fade-out", "slide-out-to-right")
    this.element.addEventListener("animationend", () => this.element.remove(), { once: true })
    // Fallback removal if animation doesn't fire
    setTimeout(() => this.element.remove(), 300)
  }
}
```

**Step 4: Verify no JS errors**

Run: `bin/rails test`
Expected: All tests pass.

**Step 5: Commit**

```bash
git add app/views/layouts/application.html.erb app/javascript/controllers/toast_controller.js config/importmap.rb
git commit -m "Add toast notification infrastructure with Turbo Stream broadcasts"
```

---

### Task 5: Update PublishArticleJob with Hugo publish and notifications

**Files:**
- Modify: `app/jobs/publish_article_job.rb`
- Modify: `test/jobs/publish_article_job_test.rb`

**Step 1: Write the updated tests**

Replace `test/jobs/publish_article_job_test.rb` entirely:

```ruby
# frozen_string_literal: true

require "test_helper"

class PublishArticleJobTest < ActiveSupport::TestCase
  should "publish a publishing article and set status to published" do
    article = create(:article, :publishing)

    HugoGitClient.stub(:new, stub_git_client) do
      PublishArticleJob.perform_now(article)
    end

    article.reload
    assert_equal "published", article.status
  end

  should "skip Hugo push when HUGO_REPO_SSH_URL is not configured and publish directly" do
    article = create(:article, :publishing)

    ClimateControl.modify(HUGO_REPO_SSH_URL: nil, HUGO_DEPLOY_KEY_PATH: nil) do
      PublishArticleJob.perform_now(article)
    end

    article.reload
    assert_equal "published", article.status
  end

  should "revert to draft on Hugo push failure" do
    article = create(:article, :publishing)

    failing_client = Minitest::Mock.new
    failing_client.expect(:clone, nil) { raise RuntimeError, "git clone failed" }

    HugoGitClient.stub(:new, failing_client) do
      ClimateControl.modify(HUGO_REPO_SSH_URL: "git@github.com:user/blog.git", HUGO_DEPLOY_KEY_PATH: "/tmp/key") do
        PublishArticleJob.perform_now(article)
      end
    end

    article.reload
    assert_equal "draft", article.status
  end

  should "not publish an article that is not in publishing state" do
    article = create(:article, :draft)
    PublishArticleJob.perform_now(article)

    article.reload
    assert_equal "draft", article.status
  end

  should "handle scheduled articles by setting publishing first" do
    article = create(:article, :scheduled, published_at: 1.minute.ago)
    article.publish_now!

    article.reload
    assert_equal "publishing", article.status
  end

  private

  def stub_git_client
    client = Minitest::Mock.new
    client.expect(:clone, true)
    client.expect(:repo_path, "/tmp/test/repo")
    client.expect(:commit_and_push, true, [String])
    client
  end
end
```

Note: This uses `climate_control` gem for ENV stubbing. If not available, we can use `ENV.stub` or add the gem.

**Step 2: Check if `climate_control` gem is available, if not use an alternative**

Run: `grep climate_control Gemfile`

If not present, replace `ClimateControl.modify(...)` blocks with:

```ruby
ENV.stub(:fetch, ->(key, default = nil) {
  return nil if %w[HUGO_REPO_SSH_URL HUGO_DEPLOY_KEY_PATH].include?(key)
  ENV.send(:original_fetch, key, default)
}) do
  ...
end
```

Or simpler: just set and unset ENV in the test. The implementation checks `ENV.fetch("HUGO_REPO_SSH_URL", nil)`.

**Step 3: Write the implementation**

Replace `app/jobs/publish_article_job.rb`:

```ruby
# frozen_string_literal: true

class PublishArticleJob < ApplicationJob
  queue_as :default

  def perform(article)
    return unless article.status == "publishing"

    hugo_publish(article)
    article.update!(status: "published")
    broadcast_toast(article, :success, "'#{article.title}' published successfully")
  rescue => e
    Rails.logger.error("Hugo publish failed for #{article.slug}: #{e.message}")
    article.update!(status: "draft")
    broadcast_toast(article, :destructive, "Failed to publish '#{article.title}'")
  end

  private

  def hugo_publish(article)
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

  def broadcast_toast(article, variant, message)
    user = Current.user || article.try(:user)
    return unless user

    html = ApplicationController.render(
      partial: "shared/toast",
      locals: { variant: variant, message: message }
    )

    Turbo::StreamsChannel.broadcast_append_to(
      user,
      target: "notifications",
      html: html
    )
  end
end
```

**Step 4: Create the toast partial**

Create `app/views/shared/_toast.html.erb`:

```erb
<div data-controller="toast" class="<%= toast_classes(variant) %>" role="alert">
  <div class="flex items-center justify-between gap-2">
    <p class="text-sm font-medium"><%= message %></p>
    <button data-action="click->toast#dismiss" class="text-current opacity-70 hover:opacity-100 cursor-pointer">
      <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>
    </button>
  </div>
</div>
```

**Step 5: Add the toast helper**

Add to `app/helpers/application_helper.rb` (or create it):

```ruby
module ApplicationHelper
  def toast_classes(variant)
    base = "rounded-lg border px-4 py-3 shadow-lg backdrop-blur"
    case variant
    when :success
      "#{base} border-green-300 bg-green-50 text-green-800 dark:border-green-700 dark:bg-green-900/80 dark:text-green-200"
    when :destructive
      "#{base} border-red-300 bg-red-50 text-red-800 dark:border-red-700 dark:bg-red-900/80 dark:text-red-200"
    else
      "#{base} border-border bg-card text-card-foreground"
    end
  end
end
```

**Step 6: Handle `Current.user` in background jobs**

`Current.user` is not available in background jobs by default. We need to pass the user to the job. Update `Article#publish_now!` in `app/models/article.rb`:

```ruby
def publish_now!
  update!(status: "publishing", published_at: Time.current)
  PublishArticleJob.perform_later(self, Current.user)
end
```

And update the job's `perform` signature:

```ruby
def perform(article, user = nil)
  return unless article.status == "publishing"

  hugo_publish(article)
  article.update!(status: "published")
  broadcast_toast(user, :success, "'#{article.title}' published successfully")
rescue => e
  Rails.logger.error("Hugo publish failed for #{article.slug}: #{e.message}")
  article.update!(status: "draft")
  broadcast_toast(user, :destructive, "Failed to publish '#{article.title}'")
end
```

Update `broadcast_toast` to take `user` directly:

```ruby
def broadcast_toast(user, variant, message)
  return unless user

  html = ApplicationController.render(
    partial: "shared/toast",
    locals: { variant: variant, message: message }
  )

  Turbo::StreamsChannel.broadcast_append_to(
    user,
    target: "notifications",
    html: html
  )
end
```

Also update `Article#schedule!` — when `PublishArticleJob` fires for scheduled articles, it calls `publish_now!` which now passes `Current.user`. But in the scheduled job context, `Current.user` won't be set. We need to handle this:

The scheduled flow is: `schedule!` -> `PublishArticleJob` fires at time -> calls `publish_now!`. But `publish_now!` now enqueues another `PublishArticleJob`. To avoid this double-job, change the flow:

For scheduled articles, `PublishArticleJob` should handle the full transition directly:

```ruby
def perform(article, user = nil)
  case article.status
  when "scheduled"
    article.update!(status: "publishing", published_at: Time.current)
    hugo_publish(article)
    article.update!(status: "published")
    broadcast_toast(user, :success, "'#{article.title}' published successfully")
  when "publishing"
    hugo_publish(article)
    article.update!(status: "published")
    broadcast_toast(user, :success, "'#{article.title}' published successfully")
  end
rescue => e
  Rails.logger.error("Hugo publish failed for #{article.slug}: #{e.message}")
  article.update!(status: "draft")
  broadcast_toast(user, :destructive, "Failed to publish '#{article.title}'")
end
```

And `publish_now!` stays simple:

```ruby
def publish_now!
  update!(status: "publishing", published_at: Time.current)
  PublishArticleJob.perform_later(self, Current.user)
end
```

And `schedule!` passes the user too:

```ruby
def schedule!(time)
  update!(status: "scheduled", published_at: time)
  PublishArticleJob.set(wait_until: time).perform_later(self, Current.user)
end
```

**Step 7: Run tests**

Run: `bin/rails test test/jobs/publish_article_job_test.rb`
Expected: All tests pass.

Run: `bin/rails test`
Expected: All tests pass.

**Step 8: Commit**

```bash
git add app/jobs/publish_article_job.rb test/jobs/publish_article_job_test.rb app/models/article.rb app/views/shared/_toast.html.erb app/helpers/application_helper.rb
git commit -m "Update PublishArticleJob with Hugo publish, status transitions, and toast notifications"
```

---

### Task 6: Lint and Final Verification

**Step 1: Run RuboCop**

Run: `bundle exec rubocop`
Expected: No offenses. Fix any that appear.

**Step 2: Run Brakeman**

Run: `bundle exec brakeman --no-pager --quiet`
Expected: No warnings.

**Step 3: Run bundler-audit**

Run: `bundle exec bundler-audit check`
Expected: No vulnerabilities.

**Step 4: Run full test suite**

Run: `bin/rails test`
Expected: All tests pass, zero failures.

**Step 5: Commit any fixes**

```bash
git add -A
git commit -m "Fix lint offenses in Hugo publish feature"
```
