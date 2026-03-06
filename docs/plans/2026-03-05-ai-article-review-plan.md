# AI Article Review Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add on-demand LLM-powered article review with inline annotations on the preview pane, using Ollama via Langchain.rb.

**Architecture:** User clicks "Review" on edit page -> POST to server -> Solid Queue job calls Ollama via Langchain.rb -> results broadcast via Solid Cable (Action Cable) -> Stimulus controller renders highlighted annotations on the preview pane with accept/dismiss actions.

**Tech Stack:** Rails 8.1, Langchain.rb (Ollama), Solid Queue, Solid Cable (Action Cable), Stimulus, Phlex

---

### Task 1: Add langchainrb gem

**Files:**
- Modify: `Gemfile`

**Step 1: Add the gem**

Add to the Gemfile (after the `redcarpet` line is a good spot):

```ruby
gem "langchainrb", require: "langchain"
```

**Step 2: Install**

Run: `bundle install`
Expected: Gem installs successfully, `Gemfile.lock` updated.

**Step 3: Commit**

```bash
git add Gemfile Gemfile.lock
git commit -m "$(cat <<'EOF'
Add langchainrb gem for LLM integration

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
```

---

### Task 2: ArticleReviewService

**Files:**
- Create: `app/services/article_review_service.rb`
- Create: `test/services/article_review_service_test.rb`

**Step 1: Write the failing test**

Create `test/services/article_review_service_test.rb`:

```ruby
# frozen_string_literal: true

require "test_helper"

class ArticleReviewServiceTest < ActiveSupport::TestCase
  setup do
    @service = ArticleReviewService.new
    @article_body = "# My Article\n\nThe impact was very significant and really important to the field."
  end

  should "return an array of annotations" do
    mock_response = Minitest::Mock.new
    mock_response.expect(:chat_completion, '[{"original_text":"very significant and really important","suggestion":"significant","category":"clarity","explanation":"Remove redundant intensifiers"}]')

    mock_llm = Minitest::Mock.new
    mock_llm.expect(:chat, mock_response, messages: Array)

    Langchain::LLM::Ollama.stub(:new, mock_llm) do
      result = @service.review(@article_body)

      assert_kind_of Array, result
      assert_equal 1, result.length
      assert_equal "clarity", result.first["category"]
      assert_equal "significant", result.first["suggestion"]
    end
  end

  should "return empty array when LLM returns no annotations" do
    mock_response = Minitest::Mock.new
    mock_response.expect(:chat_completion, "[]")

    mock_llm = Minitest::Mock.new
    mock_llm.expect(:chat, mock_response, messages: Array)

    Langchain::LLM::Ollama.stub(:new, mock_llm) do
      result = @service.review(@article_body)
      assert_equal [], result
    end
  end

  should "return error hash when LLM response is not valid JSON" do
    mock_response = Minitest::Mock.new
    mock_response.expect(:chat_completion, "This is not JSON")

    mock_llm = Minitest::Mock.new
    mock_llm.expect(:chat, mock_response, messages: Array)

    Langchain::LLM::Ollama.stub(:new, mock_llm) do
      result = @service.review(@article_body)
      assert_kind_of Hash, result
      assert_equal "parse_error", result["error"]
    end
  end

  should "return error hash when Ollama is unreachable" do
    mock_llm = Minitest::Mock.new
    mock_llm.expect(:chat, nil) do |**_args|
      raise Faraday::ConnectionFailed, "Connection refused"
    end

    Langchain::LLM::Ollama.stub(:new, mock_llm) do
      result = @service.review(@article_body)
      assert_kind_of Hash, result
      assert_equal "connection_error", result["error"]
    end
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bin/rails test test/services/article_review_service_test.rb`
Expected: FAIL — `ArticleReviewService` not defined.

**Step 3: Write the implementation**

Create `app/services/article_review_service.rb`:

```ruby
# frozen_string_literal: true

class ArticleReviewService
  SYSTEM_PROMPT = <<~PROMPT
    You are an expert writing reviewer. Analyze the provided article and return feedback as a JSON array.

    Each annotation must have these fields:
    - "original_text": the exact verbatim excerpt from the article that needs improvement
    - "suggestion": the improved replacement text
    - "category": one of "grammar", "clarity", "content", "structure"
    - "explanation": brief reason for the suggestion

    Review for:
    - Grammar and spelling errors
    - Clarity and conciseness (remove redundancy, tighten prose)
    - Content quality (logical consistency, missing points, argument strength)
    - Structure (paragraph flow, heading organization)

    Return ONLY the JSON array. No markdown fences, no preamble, no explanation outside the array.
    If the article needs no improvements, return an empty array: []
  PROMPT

  def initialize
    @llm = Langchain::LLM::Ollama.new(
      url: ENV.fetch("OLLAMA_URL", "http://localhost:11434"),
      default_options: { chat_model: ENV.fetch("OLLAMA_MODEL", "qwen2.5:14b") }
    )
  end

  def review(article_body)
    response = @llm.chat(messages: [
      { role: "system", content: SYSTEM_PROMPT },
      { role: "user", content: article_body }
    ])
    JSON.parse(response.chat_completion)
  rescue JSON::ParserError
    { "error" => "parse_error", "message" => "Could not parse review results" }
  rescue Faraday::ConnectionFailed, Faraday::TimeoutError
    { "error" => "connection_error", "message" => "Review service unavailable" }
  end
end
```

**Step 4: Run test to verify it passes**

Run: `bin/rails test test/services/article_review_service_test.rb`
Expected: 4 tests, 4 assertions, 0 failures.

**Step 5: Run rubocop**

Run: `bundle exec rubocop app/services/article_review_service.rb test/services/article_review_service_test.rb`
Expected: No offenses.

**Step 6: Commit**

```bash
git add app/services/article_review_service.rb test/services/article_review_service_test.rb
git commit -m "$(cat <<'EOF'
Add ArticleReviewService with Langchain.rb Ollama integration

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
```

---

### Task 3: ArticleReviewChannel (Action Cable)

**Files:**
- Create: `app/channels/article_review_channel.rb`
- Create: `test/channels/article_review_channel_test.rb`

**Step 1: Write the failing test**

Create `test/channels/article_review_channel_test.rb`:

```ruby
# frozen_string_literal: true

require "test_helper"

class ArticleReviewChannelTest < ActionCable::Channel::TestCase
  setup do
    @article = create(:article)
  end

  should "subscribe to article-specific stream" do
    stub_connection(current_user: @article.user || create(:user))
    subscribe(article_id: @article.id)

    assert subscription.confirmed?
    assert_has_stream "article_review_#{@article.id}"
  end

  should "reject subscription without article_id" do
    stub_connection(current_user: create(:user))
    subscribe(article_id: nil)

    assert subscription.rejected?
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bin/rails test test/channels/article_review_channel_test.rb`
Expected: FAIL — `ArticleReviewChannel` not defined.

**Step 3: Write the implementation**

Create `app/channels/article_review_channel.rb`:

```ruby
# frozen_string_literal: true

class ArticleReviewChannel < ApplicationCable::Channel
  def subscribed
    if params[:article_id].present?
      stream_from "article_review_#{params[:article_id]}"
    else
      reject
    end
  end
end
```

**Step 4: Run test to verify it passes**

Run: `bin/rails test test/channels/article_review_channel_test.rb`
Expected: 2 tests, 0 failures.

**Step 5: Commit**

```bash
git add app/channels/article_review_channel.rb test/channels/article_review_channel_test.rb
git commit -m "$(cat <<'EOF'
Add ArticleReviewChannel for broadcasting review results

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
```

---

### Task 4: ArticleReviewJob

**Files:**
- Create: `app/jobs/article_review_job.rb`
- Create: `test/jobs/article_review_job_test.rb`

**Step 1: Write the failing test**

Create `test/jobs/article_review_job_test.rb`:

```ruby
# frozen_string_literal: true

require "test_helper"

class ArticleReviewJobTest < ActiveSupport::TestCase
  setup do
    @article = create(:article, body: "# Test\n\nSome article content here.")
  end

  should "call ArticleReviewService and broadcast results" do
    annotations = [
      { "original_text" => "Some article", "suggestion" => "An article", "category" => "clarity", "explanation" => "More concise" }
    ]

    mock_service = Minitest::Mock.new
    mock_service.expect(:review, annotations, [@article.body])

    ArticleReviewService.stub(:new, mock_service) do
      assert_broadcasts("article_review_#{@article.id}", 1) do
        ArticleReviewJob.perform_now(@article)
      end
    end
  end

  should "broadcast error when service returns error" do
    error_result = { "error" => "connection_error", "message" => "Review service unavailable" }

    mock_service = Minitest::Mock.new
    mock_service.expect(:review, error_result, [@article.body])

    ArticleReviewService.stub(:new, mock_service) do
      assert_broadcasts("article_review_#{@article.id}", 1) do
        ArticleReviewJob.perform_now(@article)
      end
    end
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bin/rails test test/jobs/article_review_job_test.rb`
Expected: FAIL — `ArticleReviewJob` not defined.

**Step 3: Write the implementation**

Create `app/jobs/article_review_job.rb`:

```ruby
# frozen_string_literal: true

class ArticleReviewJob < ApplicationJob
  queue_as :default

  def perform(article)
    result = ArticleReviewService.new.review(article.body)

    ActionCable.server.broadcast(
      "article_review_#{article.id}",
      result
    )
  end
end
```

**Step 4: Run test to verify it passes**

Run: `bin/rails test test/jobs/article_review_job_test.rb`
Expected: 2 tests, 0 failures.

**Step 5: Commit**

```bash
git add app/jobs/article_review_job.rb test/jobs/article_review_job_test.rb
git commit -m "$(cat <<'EOF'
Add ArticleReviewJob to process reviews in background

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
```

---

### Task 5: ArticleReviewsController + Route

**Files:**
- Create: `app/controllers/articles/reviews_controller.rb`
- Create: `test/controllers/articles/reviews_controller_test.rb`
- Modify: `config/routes.rb`

**Step 1: Write the failing test**

Create `test/controllers/articles/reviews_controller_test.rb`:

```ruby
# frozen_string_literal: true

require "test_helper"

class Articles::ReviewsControllerTest < ActionDispatch::IntegrationTest
  context "unauthenticated" do
    should "redirect to login" do
      article = create(:article)
      post article_review_path(slug: article.slug)
      assert_redirected_to new_session_path
    end
  end

  context "POST #create (authenticated)" do
    setup do
      @user = create(:user)
      sign_in(@user)
      @article = create(:article, body: "Some content to review.")
    end

    should "enqueue ArticleReviewJob and return success" do
      assert_enqueued_with(job: ArticleReviewJob) do
        post article_review_path(slug: @article.slug)
      end
      assert_response :success
    end

    should "return 404 for non-existent article" do
      assert_raises(ActiveRecord::RecordNotFound) do
        post article_review_path(slug: "non-existent")
      end
    end
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bin/rails test test/controllers/articles/reviews_controller_test.rb`
Expected: FAIL — route not defined.

**Step 3: Add the route**

In `config/routes.rb`, add within the `resources :articles` member block:

```ruby
post :review, to: "articles/reviews#create"
```

The member block should look like:

```ruby
member do
  post :publish, to: "articles/publishes#create"
  get :preview, to: "articles/previews#show"
  get :export, to: "articles/exports#create"
  post :review, to: "articles/reviews#create"
end
```

**Step 4: Write the controller**

Create `app/controllers/articles/reviews_controller.rb`:

```ruby
# frozen_string_literal: true

module Articles
  class ReviewsController < ApplicationController
    def create
      article = Article.find_by!(slug: params[:slug])
      ArticleReviewJob.perform_later(article)
      head :accepted
    end
  end
end
```

**Step 5: Run test to verify it passes**

Run: `bin/rails test test/controllers/articles/reviews_controller_test.rb`
Expected: 3 tests, 0 failures.

**Step 6: Commit**

```bash
git add app/controllers/articles/reviews_controller.rb test/controllers/articles/reviews_controller_test.rb config/routes.rb
git commit -m "$(cat <<'EOF'
Add review route and controller to enqueue article review jobs

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
```

---

### Task 6: Stimulus article-review controller

**Files:**
- Create: `app/javascript/controllers/article_review_controller.js`

This is the most complex piece. The controller:
1. Subscribes to Action Cable for the article
2. Sends POST to trigger review
3. Receives annotations and renders them as highlights + margin comments on the preview pane
4. Handles accept (find-and-replace in textarea) and dismiss

**Step 1: Create the Stimulus controller**

Create `app/javascript/controllers/article_review_controller.js`:

```javascript
import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

export default class extends Controller {
  static targets = ["button", "input", "preview"]
  static values = { articleId: Number }

  connect() {
    this.annotations = []
    this.subscription = null
  }

  disconnect() {
    this.unsubscribe()
  }

  review() {
    this.clearAnnotations()
    this.showLoading()
    this.subscribe()

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    fetch(this.buttonTarget.dataset.reviewUrl, {
      method: "POST",
      headers: {
        "X-CSRF-Token": csrfToken,
        "Accept": "application/json"
      }
    }).catch(() => {
      this.showError("Failed to send review request")
      this.hideLoading()
    })
  }

  subscribe() {
    if (this.subscription) return

    this.subscription = createConsumer().subscriptions.create(
      { channel: "ArticleReviewChannel", article_id: this.articleIdValue },
      {
        received: (data) => {
          this.hideLoading()
          if (data.error) {
            this.showError(data.message)
          } else {
            this.annotations = data
            this.renderAnnotations()
          }
          this.unsubscribe()
        }
      }
    )
  }

  unsubscribe() {
    if (this.subscription) {
      this.subscription.unsubscribe()
      this.subscription = null
    }
  }

  renderAnnotations() {
    const preview = this.previewTarget
    if (!this.annotations.length) {
      this.showSuccess("No suggestions found -- your article looks good!")
      return
    }

    const categoryColors = {
      grammar: "bg-red-100 border-red-300 dark:bg-red-900/30 dark:border-red-700",
      clarity: "bg-yellow-100 border-yellow-300 dark:bg-yellow-900/30 dark:border-yellow-700",
      content: "bg-blue-100 border-blue-300 dark:bg-blue-900/30 dark:border-blue-700",
      structure: "bg-purple-100 border-purple-300 dark:bg-purple-900/30 dark:border-purple-700"
    }

    const highlightColors = {
      grammar: "bg-red-200/50 dark:bg-red-800/30",
      clarity: "bg-yellow-200/50 dark:bg-yellow-800/30",
      content: "bg-blue-200/50 dark:bg-blue-800/30",
      structure: "bg-purple-200/50 dark:bg-purple-800/30"
    }

    this.annotations.forEach((annotation, index) => {
      const escapedText = annotation.original_text.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")
      const walker = document.createTreeWalker(preview, NodeFilter.SHOW_TEXT)
      let node

      while ((node = walker.nextNode())) {
        const nodeText = node.textContent
        const matchIndex = nodeText.indexOf(annotation.original_text)
        if (matchIndex === -1) continue

        const range = document.createRange()
        range.setStart(node, matchIndex)
        range.setEnd(node, matchIndex + annotation.original_text.length)

        const mark = document.createElement("mark")
        mark.className = `relative cursor-pointer rounded px-0.5 ${highlightColors[annotation.category] || highlightColors.clarity}`
        mark.dataset.annotationIndex = index
        mark.addEventListener("click", () => this.toggleComment(index))
        range.surroundContents(mark)

        // Create margin comment
        const comment = document.createElement("div")
        comment.id = `review-comment-${index}`
        comment.className = `hidden absolute right-0 translate-x-full top-0 ml-2 w-72 p-3 rounded-lg border shadow-lg z-50 text-sm ${categoryColors[annotation.category] || categoryColors.clarity}`
        comment.innerHTML = `
          <div class="flex items-center gap-2 mb-2">
            <span class="text-xs font-semibold uppercase tracking-wide">${annotation.category}</span>
          </div>
          <p class="text-foreground mb-2">${this.escapeHtml(annotation.explanation)}</p>
          <div class="bg-background/50 rounded p-2 mb-2 font-mono text-xs">
            <span class="line-through text-muted-foreground">${this.escapeHtml(annotation.original_text)}</span>
            <br>
            <span class="text-green-700 dark:text-green-400">${this.escapeHtml(annotation.suggestion)}</span>
          </div>
          <div class="flex gap-2">
            <button data-action="click->article-review#accept" data-index="${index}"
              class="px-2 py-1 text-xs bg-green-600 text-white rounded hover:bg-green-700 cursor-pointer">Accept</button>
            <button data-action="click->article-review#dismiss" data-index="${index}"
              class="px-2 py-1 text-xs bg-muted text-muted-foreground rounded hover:bg-muted/80 cursor-pointer">Dismiss</button>
          </div>
        `
        mark.style.position = "relative"
        mark.appendChild(comment)
        break
      }
    })
  }

  toggleComment(index) {
    const comment = document.getElementById(`review-comment-${index}`)
    if (!comment) return

    // Hide all other comments
    document.querySelectorAll("[id^='review-comment-']").forEach(el => {
      if (el !== comment) el.classList.add("hidden")
    })

    comment.classList.toggle("hidden")
  }

  accept(event) {
    const index = parseInt(event.currentTarget.dataset.index)
    const annotation = this.annotations[index]
    if (!annotation) return

    // Replace in textarea
    const textarea = this.inputTarget
    const currentValue = textarea.value
    const newValue = currentValue.replace(annotation.original_text, annotation.suggestion)
    textarea.value = newValue

    // Trigger markdown preview update
    textarea.dispatchEvent(new Event("input", { bubbles: true }))

    this.removeAnnotation(index)
  }

  dismiss(event) {
    const index = parseInt(event.currentTarget.dataset.index)
    this.removeAnnotation(index)
  }

  removeAnnotation(index) {
    const mark = this.previewTarget.querySelector(`mark[data-annotation-index="${index}"]`)
    if (mark) {
      const parent = mark.parentNode
      while (mark.firstChild) {
        // Don't move the comment div back
        if (mark.firstChild.id?.startsWith("review-comment-")) {
          mark.removeChild(mark.firstChild)
        } else {
          parent.insertBefore(mark.firstChild, mark)
        }
      }
      parent.removeChild(mark)
      parent.normalize()
    }
  }

  clearAnnotations() {
    this.previewTarget.querySelectorAll("mark[data-annotation-index]").forEach(mark => {
      const parent = mark.parentNode
      while (mark.firstChild) {
        if (mark.firstChild.id?.startsWith("review-comment-")) {
          mark.removeChild(mark.firstChild)
        } else {
          parent.insertBefore(mark.firstChild, mark)
        }
      }
      parent.removeChild(mark)
      parent.normalize()
    })
    this.annotations = []
  }

  showLoading() {
    this.buttonTarget.disabled = true
    this.buttonTarget.dataset.originalText = this.buttonTarget.textContent
    this.buttonTarget.textContent = "Reviewing..."
    this.buttonTarget.classList.add("animate-pulse")
  }

  hideLoading() {
    this.buttonTarget.disabled = false
    this.buttonTarget.textContent = this.buttonTarget.dataset.originalText || "Review"
    this.buttonTarget.classList.remove("animate-pulse")
  }

  showError(message) {
    this.showFlash(message, "text-destructive")
  }

  showSuccess(message) {
    this.showFlash(message, "text-green-600 dark:text-green-400")
  }

  showFlash(message, colorClass) {
    const flash = document.createElement("div")
    flash.className = `text-sm ${colorClass} mt-2`
    flash.textContent = message
    this.buttonTarget.parentElement.appendChild(flash)
    setTimeout(() => flash.remove(), 5000)
  }

  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }
}
```

**Step 2: Register the controller**

The controller should auto-register via the import map and Stimulus autoload (check `app/javascript/controllers/index.js` uses `eagerLoadControllersFrom`). If the project uses stimulus-loading, no manual registration needed.

Verify: `grep -r "eagerLoadControllersFrom\|controllers" app/javascript/controllers/index.js`

**Step 3: Add actioncable to importmap if not present**

Check `config/importmap.rb` for `@rails/actioncable`. If missing, add:

Run: `bin/importmap pin @rails/actioncable`

**Step 4: Manual test in browser**

Open an article edit form, verify no JS errors in console.

**Step 5: Commit**

```bash
git add app/javascript/controllers/article_review_controller.js config/importmap.rb
git commit -m "$(cat <<'EOF'
Add Stimulus article-review controller with Action Cable integration

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
```

---

### Task 7: Wire up the Review button in the article form view

**Files:**
- Modify: `app/components/admin/markdown_preview.rb`

The `MarkdownPreview` component wraps the textarea and preview pane. We need to:
1. Wrap it with the `article-review` Stimulus controller
2. Add `data-article-review-target` attributes to the textarea and preview div
3. Add a "Review" button
4. Pass the article ID for the Action Cable subscription

**Step 1: Read the current component**

Read: `app/components/admin/markdown_preview.rb` (already read above — it has `markdown-preview` controller on the outer div, with `input` and `preview` targets).

**Step 2: Modify the component to accept article_id**

Modify `app/components/admin/markdown_preview.rb` to add article_id parameter and the review controller:

```ruby
# frozen_string_literal: true

class Components::Admin::MarkdownPreview < Components::Base
  def initialize(body: "", article_id: nil)
    @body = body
    @article_id = article_id
  end

  def view_template
    div(
      class: "grid grid-cols-2 gap-4 h-[60vh]",
      data: controllers_data
    ) do
      # Editor pane
      div(class: "flex flex-col") do
        div(class: "flex items-center justify-between mb-2") do
          label(class: "text-sm font-medium text-foreground") { "Markdown" }
          review_button if @article_id
        end
        textarea(
          name: "article[body]",
          class: "flex-1 w-full p-4 font-mono text-sm border border-input rounded-lg bg-background text-foreground resize-none focus:outline-none focus:ring-2 focus:ring-ring",
          data: { markdown_preview_target: "input", article_review_target: "input", action: "input->markdown-preview#update" },
          placeholder: "Write your article in markdown..."
        ) { plain @body }
      end

      # Preview pane
      div(class: "flex flex-col") do
        label(class: "text-sm font-medium text-foreground mb-2") { "Preview" }
        div(
          class: "flex-1 overflow-y-auto p-4 border border-input rounded-lg bg-background prose prose-sm dark:prose-invert max-w-none relative",
          data: { markdown_preview_target: "preview", article_review_target: "preview" }
        ) do
          raw safe(MarkdownRenderer.render(@body)) if @body.present?
        end
      end
    end
  end

  private

  def controllers_data
    data = { controller: "markdown-preview" }
    if @article_id
      data[:controller] += " article-review"
      data[:article_review_article_id_value] = @article_id
    end
    data
  end

  def review_button
    button(
      type: "button",
      class: "px-3 py-1 text-xs bg-secondary text-secondary-foreground rounded-lg hover:bg-secondary/80 transition-colors cursor-pointer",
      data: {
        article_review_target: "button",
        action: "click->article-review#review",
        review_url: helpers.article_review_path(slug: find_article_slug)
      }
    ) { "Review" }
  end

  def find_article_slug
    # The article slug is needed for the review URL.
    # We look it up from the ID passed in.
    Article.find(@article_id).slug
  end
end
```

**Step 3: Update the form to pass article_id**

Modify `app/views/admin/articles/form.rb` line 65 to pass the article ID:

Change:
```ruby
render Components::Admin::MarkdownPreview.new(body: @article.body)
```

To:
```ruby
render Components::Admin::MarkdownPreview.new(body: @article.body, article_id: @article.persisted? ? @article.id : nil)
```

This ensures the review button only shows for saved articles (not new article form).

**Step 4: Run all tests**

Run: `bin/rails test`
Expected: All tests pass.

**Step 5: Run rubocop**

Run: `bundle exec rubocop app/components/admin/markdown_preview.rb app/views/admin/articles/form.rb`
Expected: No offenses.

**Step 6: Commit**

```bash
git add app/components/admin/markdown_preview.rb app/views/admin/articles/form.rb
git commit -m "$(cat <<'EOF'
Wire up Review button in article form with Stimulus controller

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
```

---

### Task 8: System test for the review flow

**Files:**
- Create: `test/system/article_review_test.rb`

**Step 1: Write the system test**

Create `test/system/article_review_test.rb`:

```ruby
# frozen_string_literal: true

require "application_system_test_case"

class ArticleReviewTest < ApplicationSystemTestCase
  setup do
    @user = create(:user)
    @article = create(:article, :published, body: "# Test Article\n\nThe impact was very significant and really important.")
    sign_in_system(@user)
  end

  test "review button appears on article edit page" do
    visit edit_article_path(slug: @article.slug)
    within("turbo-frame#modal") do
      assert_selector "button", text: "Review"
    end
  end

  test "review button does not appear on new article page" do
    visit new_article_path
    within("turbo-frame#modal") do
      assert_no_selector "button", text: "Review"
    end
  end

  private

  def sign_in_system(user)
    visit new_session_path
    fill_in "email_address", with: user.email_address
    fill_in "password", with: "password"
    click_button "Sign in"
  end
end
```

Note: Full end-to-end review flow testing with Ollama stubbing is complex in system tests. The unit/integration tests (service, job, controller) cover the backend flow. The system test verifies UI presence.

**Step 2: Run the system test**

Run: `bin/rails test:system test/system/article_review_test.rb`
Expected: Tests pass (button visible on edit, not on new).

**Step 3: Commit**

```bash
git add test/system/article_review_test.rb
git commit -m "$(cat <<'EOF'
Add system tests for article review button presence

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
```

---

### Task 9: Full test suite + linting verification

**Step 1: Run full test suite**

Run: `bin/rails test`
Expected: All tests pass, 0 failures.

**Step 2: Run system tests**

Run: `bin/rails test:system`
Expected: All tests pass.

**Step 3: Run rubocop**

Run: `bundle exec rubocop`
Expected: 0 offenses.

**Step 4: Run brakeman**

Run: `bundle exec brakeman --no-pager --quiet`
Expected: No warnings.

**Step 5: Run bundler-audit**

Run: `bundle exec bundler-audit check`
Expected: No vulnerabilities.

**Step 6: Final commit if any fixes were needed**

If any linting or test fixes were needed, commit them.
