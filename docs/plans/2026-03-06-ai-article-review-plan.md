# AI Article Review Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add an AI-powered article review feature with two parallel review processes (Content + SEO), presenting individual accept/reject suggestions with diff confirmation.

**Architecture:** User clicks "Review Article" in a new Review tab inside the edit form dialog. Controller creates an `ArticleReview` record and enqueues two parallel jobs (`ContentReviewJob`, `SeoReviewJob`). Each job calls Google Gemini via the `langchain` gem, parses structured JSON into `ReviewSuggestion` records, and broadcasts results via Turbo Streams. User accepts/rejects suggestions individually; accepting shows a diff before applying the change.

**Tech Stack:** Rails 8.1, Langchain (langchainrb gem) with Google Gemini, Solid Queue, Solid Cable (Action Cable), Phlex + RubyUI, Stimulus

---

### Task 1: Add langchainrb Gem

**Files:**
- Modify: `Gemfile`

**Step 1: Add the gem**

Add to `Gemfile` (after the `rouge` gem line):

```ruby
# LLM integration via Langchain
gem "langchainrb"
gem "gemini-ai"
```

**Step 2: Install**

```bash
bundle install
```

**Step 3: Commit**

```bash
git add Gemfile Gemfile.lock
git commit -m "Add langchainrb and gemini-ai gems"
```

---

### Task 2: Create ArticleReview and ReviewSuggestion Models

**Files:**
- Create: `db/migrate/TIMESTAMP_create_article_reviews.rb`
- Create: `db/migrate/TIMESTAMP_create_review_suggestions.rb`
- Create: `app/models/article_review.rb`
- Create: `app/models/review_suggestion.rb`
- Modify: `app/models/article.rb`
- Create: `test/models/article_review_test.rb`
- Create: `test/models/review_suggestion_test.rb`
- Create: `test/factories/article_reviews.rb`
- Create: `test/factories/review_suggestions.rb`

**Step 1: Generate migrations**

```bash
bin/rails generate migration CreateArticleReviews article:references content_status:string seo_status:string
bin/rails generate migration CreateReviewSuggestions article_review:references process:string category:string original_text:text suggested_text:text explanation:text status:string
```

**Step 2: Edit the migrations**

Edit `CreateArticleReviews` migration:

```ruby
class CreateArticleReviews < ActiveRecord::Migration[8.1]
  def change
    create_table :article_reviews do |t|
      t.references :article, null: false, foreign_key: true
      t.string :content_status, null: false, default: "pending"
      t.string :seo_status, null: false, default: "pending"
      t.timestamps
    end
  end
end
```

Edit `CreateReviewSuggestions` migration:

```ruby
class CreateReviewSuggestions < ActiveRecord::Migration[8.1]
  def change
    create_table :review_suggestions do |t|
      t.references :article_review, null: false, foreign_key: true
      t.string :process, null: false
      t.string :category, null: false
      t.text :original_text
      t.text :suggested_text, null: false
      t.text :explanation, null: false
      t.string :status, null: false, default: "pending"
      t.timestamps
    end
  end
end
```

**Step 3: Run migrations**

```bash
bin/rails db:migrate
```

**Step 4: Write model tests**

Create `test/models/article_review_test.rb`:

```ruby
require "test_helper"

class ArticleReviewTest < ActiveSupport::TestCase
  should belong_to(:article)
  should have_many(:review_suggestions).dependent(:destroy)

  should validate_presence_of(:content_status)
  should validate_presence_of(:seo_status)
  should validate_inclusion_of(:content_status).in_array(%w[pending completed failed])
  should validate_inclusion_of(:seo_status).in_array(%w[pending completed failed])

  should "default statuses to pending" do
    review = create(:article_review)
    assert_equal "pending", review.content_status
    assert_equal "pending", review.seo_status
  end
end
```

Create `test/models/review_suggestion_test.rb`:

```ruby
require "test_helper"

class ReviewSuggestionTest < ActiveSupport::TestCase
  should belong_to(:article_review)

  should validate_presence_of(:process)
  should validate_presence_of(:category)
  should validate_presence_of(:suggested_text)
  should validate_presence_of(:explanation)
  should validate_presence_of(:status)
  should validate_inclusion_of(:process).in_array(%w[content seo])
  should validate_inclusion_of(:category).in_array(%w[grammar clarity tone structure title seo summary tags])
  should validate_inclusion_of(:status).in_array(%w[pending accepted rejected])

  should "default status to pending" do
    suggestion = create(:review_suggestion)
    assert_equal "pending", suggestion.status
  end
end
```

**Step 5: Run tests to verify they fail**

```bash
bin/rails test test/models/article_review_test.rb test/models/review_suggestion_test.rb
```

Expected: FAIL (models don't exist yet).

**Step 6: Create models**

Create `app/models/article_review.rb`:

```ruby
class ArticleReview < ApplicationRecord
  belongs_to :article
  has_many :review_suggestions, dependent: :destroy

  validates :content_status, presence: true, inclusion: { in: %w[pending completed failed] }
  validates :seo_status, presence: true, inclusion: { in: %w[pending completed failed] }
end
```

Create `app/models/review_suggestion.rb`:

```ruby
class ReviewSuggestion < ApplicationRecord
  belongs_to :article_review

  validates :process, presence: true, inclusion: { in: %w[content seo] }
  validates :category, presence: true, inclusion: { in: %w[grammar clarity tone structure title seo summary tags] }
  validates :suggested_text, presence: true
  validates :explanation, presence: true
  validates :status, presence: true, inclusion: { in: %w[pending accepted rejected] }
end
```

Add association to `app/models/article.rb` (after `has_many_attached :images`):

```ruby
  has_many :article_reviews, dependent: :destroy
```

**Step 7: Create factories**

Create `test/factories/article_reviews.rb`:

```ruby
FactoryBot.define do
  factory :article_review do
    article
    content_status { "pending" }
    seo_status { "pending" }
  end
end
```

Create `test/factories/review_suggestions.rb`:

```ruby
FactoryBot.define do
  factory :review_suggestion do
    article_review
    process { "content" }
    category { "grammar" }
    original_text { "This is a orginal text." }
    suggested_text { "This is an original text." }
    explanation { "Fixed article: 'a' should be 'an' before a vowel." }
    status { "pending" }

    trait :seo do
      process { "seo" }
      category { "title" }
      original_text { "My Article" }
      suggested_text { "10 Tips for Writing Better Articles" }
      explanation { "More engaging and SEO-friendly title." }
    end

    trait :accepted do
      status { "accepted" }
    end

    trait :rejected do
      status { "rejected" }
    end
  end
end
```

**Step 8: Run tests**

```bash
bin/rails test test/models/article_review_test.rb test/models/review_suggestion_test.rb
```

Expected: All PASS.

**Step 9: Commit**

```bash
git add -A
git commit -m "Add ArticleReview and ReviewSuggestion models with tests"
```

---

### Task 3: Create ReviewService (Langchain Integration)

**Files:**
- Create: `app/services/review_service.rb`
- Create: `test/services/review_service_test.rb`

**Step 1: Write tests**

Create `test/services/review_service_test.rb`:

```ruby
require "test_helper"

class ReviewServiceTest < ActiveSupport::TestCase
  setup do
    @article = create(:article, :draft, title: "My Article", body: "This is a test artcle about Ruby on Rails.")
  end

  should "return parsed content review suggestions" do
    fake_response = [
      { "category" => "grammar", "original_text" => "artcle", "suggested_text" => "article", "explanation" => "Typo fix" }
    ].to_json

    service = ReviewService.new
    result = service.stub(:call_llm, fake_response) do
      service.content_review(@article)
    end

    assert_equal 1, result.length
    assert_equal "grammar", result.first[:category]
    assert_equal "artcle", result.first[:original_text]
    assert_equal "article", result.first[:suggested_text]
  end

  should "return parsed seo review suggestions" do
    fake_response = [
      { "category" => "title", "original_text" => "My Article", "suggested_text" => "Ruby on Rails Guide", "explanation" => "More descriptive" }
    ].to_json

    service = ReviewService.new
    result = service.stub(:call_llm, fake_response) do
      service.seo_review(@article)
    end

    assert_equal 1, result.length
    assert_equal "title", result.first[:category]
  end

  should "return empty array on invalid JSON response" do
    service = ReviewService.new
    result = service.stub(:call_llm, "not valid json") do
      service.content_review(@article)
    end

    assert_equal [], result
  end
end
```

**Step 2: Run tests to verify they fail**

```bash
bin/rails test test/services/review_service_test.rb
```

Expected: FAIL.

**Step 3: Implement ReviewService**

Create `app/services/review_service.rb`:

```ruby
class ReviewService
  CONTENT_PROMPT = <<~PROMPT
    You are an expert editor. Review the following article and provide suggestions for improvements.
    Focus on: grammar, clarity, tone, and structure.

    For each suggestion, respond with a JSON array of objects with these exact keys:
    - "category": one of "grammar", "clarity", "tone", "structure"
    - "original_text": the exact text from the article that needs improvement (copy it exactly)
    - "suggested_text": your suggested replacement
    - "explanation": brief explanation of why this change improves the article

    Respond with ONLY a valid JSON array. No markdown, no code fences, no extra text.

    Article title: %{title}
    Article body:
    %{body}
  PROMPT

  SEO_PROMPT = <<~PROMPT
    You are an SEO and content strategy expert. Review the following article and provide suggestions.
    Focus on: title improvements, SEO optimization, summary/excerpt, and tags/categories.

    For each suggestion, respond with a JSON array of objects with these exact keys:
    - "category": one of "title", "seo", "summary", "tags"
    - "original_text": the current text being improved (or null for new additions like tags)
    - "suggested_text": your suggested improvement or addition
    - "explanation": brief explanation of why this improves the article's reach

    Respond with ONLY a valid JSON array. No markdown, no code fences, no extra text.

    Article title: %{title}
    Article body:
    %{body}
  PROMPT

  def content_review(article)
    prompt = format(CONTENT_PROMPT, title: article.title, body: article.body)
    parse_response(call_llm(prompt))
  end

  def seo_review(article)
    prompt = format(SEO_PROMPT, title: article.title, body: article.body)
    parse_response(call_llm(prompt))
  end

  def call_llm(prompt)
    llm = Langchain::LLM::GoogleGemini.new(
      api_key: ENV.fetch("GEMINI_API_KEY"),
      default_options: { chat_model: "gemini-2.5-flash" }
    )
    response = llm.chat(messages: [ { role: "user", parts: [ { text: prompt } ] } ])
    response.chat_completion
  end

  private

  def parse_response(response_text)
    cleaned = response_text.to_s.gsub(/\A```json\s*/, "").gsub(/\s*```\z/, "").strip
    suggestions = JSON.parse(cleaned)
    return [] unless suggestions.is_a?(Array)

    suggestions.map do |s|
      {
        category: s["category"],
        original_text: s["original_text"],
        suggested_text: s["suggested_text"],
        explanation: s["explanation"]
      }
    end
  rescue JSON::ParserError => e
    Rails.logger.error("ReviewService JSON parse error: #{e.message}")
    []
  end
end
```

**Step 4: Run tests**

```bash
bin/rails test test/services/review_service_test.rb
```

Expected: All PASS.

**Step 5: Commit**

```bash
git add app/services/review_service.rb test/services/review_service_test.rb
git commit -m "Add ReviewService with Langchain/Gemini integration"
```

---

### Task 4: Create Review Jobs (ContentReviewJob + SeoReviewJob)

**Files:**
- Create: `app/jobs/content_review_job.rb`
- Create: `app/jobs/seo_review_job.rb`
- Create: `test/jobs/content_review_job_test.rb`
- Create: `test/jobs/seo_review_job_test.rb`

**Step 1: Write tests**

Create `test/jobs/content_review_job_test.rb`:

```ruby
require "test_helper"

class ContentReviewJobTest < ActiveSupport::TestCase
  setup do
    @article = create(:article, :draft)
    @review = create(:article_review, article: @article)
    @user = create(:user)
  end

  should "create review suggestions and update status to completed" do
    fake_suggestions = [
      { category: "grammar", original_text: "bad text", suggested_text: "good text", explanation: "Fix" }
    ]

    ReviewService.any_instance.stubs(:content_review).returns(fake_suggestions)

    ContentReviewJob.perform_now(@review, @user)

    @review.reload
    assert_equal "completed", @review.content_status
    assert_equal 1, @review.review_suggestions.where(process: "content").count
  end

  should "set status to failed when service raises" do
    ReviewService.any_instance.stubs(:content_review).raises(StandardError.new("API error"))

    ContentReviewJob.perform_now(@review, @user)

    @review.reload
    assert_equal "failed", @review.content_status
  end
end
```

Create `test/jobs/seo_review_job_test.rb`:

```ruby
require "test_helper"

class SeoReviewJobTest < ActiveSupport::TestCase
  setup do
    @article = create(:article, :draft)
    @review = create(:article_review, article: @article)
    @user = create(:user)
  end

  should "create review suggestions and update status to completed" do
    fake_suggestions = [
      { category: "title", original_text: "Old Title", suggested_text: "New Title", explanation: "Better" }
    ]

    ReviewService.any_instance.stubs(:seo_review).returns(fake_suggestions)

    SeoReviewJob.perform_now(@review, @user)

    @review.reload
    assert_equal "completed", @review.seo_status
    assert_equal 1, @review.review_suggestions.where(process: "seo").count
  end

  should "set status to failed when service raises" do
    ReviewService.any_instance.stubs(:seo_review).raises(StandardError.new("API error"))

    SeoReviewJob.perform_now(@review, @user)

    @review.reload
    assert_equal "failed", @review.seo_status
  end
end
```

**Step 2: Run tests to verify they fail**

```bash
bin/rails test test/jobs/content_review_job_test.rb test/jobs/seo_review_job_test.rb
```

Expected: FAIL.

**Step 3: Implement jobs**

Create `app/jobs/content_review_job.rb`:

```ruby
class ContentReviewJob < ApplicationJob
  queue_as :default

  def perform(review, user)
    suggestions = ReviewService.new.content_review(review.article)

    suggestions.each do |s|
      review.review_suggestions.create!(
        process: "content",
        category: s[:category],
        original_text: s[:original_text],
        suggested_text: s[:suggested_text],
        explanation: s[:explanation]
      )
    end

    review.update!(content_status: "completed")
    broadcast_suggestions(review, user, "content")
  rescue => e
    Rails.logger.error("ContentReviewJob failed: #{e.class} - #{e.message}")
    review.update!(content_status: "failed")
    broadcast_error(review, user, "content")
  end

  private

  def broadcast_suggestions(review, user, process)
    html = ApplicationController.render(
      Views::Admin::Articles::ReviewSuggestionsList.new(
        suggestions: review.review_suggestions.where(process: process),
        article: review.article
      ),
      layout: false
    )

    Turbo::StreamsChannel.broadcast_replace_to(
      user,
      target: "#{process}-review-results",
      html: html
    )
  end

  def broadcast_error(review, user, process)
    Turbo::StreamsChannel.broadcast_replace_to(
      user,
      target: "#{process}-review-results",
      html: "<p class='text-sm text-destructive'>Review failed. Please try again.</p>"
    )
  end
end
```

Create `app/jobs/seo_review_job.rb`:

```ruby
class SeoReviewJob < ApplicationJob
  queue_as :default

  def perform(review, user)
    suggestions = ReviewService.new.seo_review(review.article)

    suggestions.each do |s|
      review.review_suggestions.create!(
        process: "seo",
        category: s[:category],
        original_text: s[:original_text],
        suggested_text: s[:suggested_text],
        explanation: s[:explanation]
      )
    end

    review.update!(seo_status: "completed")
    broadcast_suggestions(review, user, "seo")
  rescue => e
    Rails.logger.error("SeoReviewJob failed: #{e.class} - #{e.message}")
    review.update!(seo_status: "failed")
    broadcast_error(review, user, "seo")
  end

  private

  def broadcast_suggestions(review, user, process)
    html = ApplicationController.render(
      Views::Admin::Articles::ReviewSuggestionsList.new(
        suggestions: review.review_suggestions.where(process: process),
        article: review.article
      ),
      layout: false
    )

    Turbo::StreamsChannel.broadcast_replace_to(
      user,
      target: "#{process}-review-results",
      html: html
    )
  end

  def broadcast_error(review, user, process)
    Turbo::StreamsChannel.broadcast_replace_to(
      user,
      target: "#{process}-review-results",
      html: "<p class='text-sm text-destructive'>Review failed. Please try again.</p>"
    )
  end
end
```

**Step 4: Add mocha gem for stubs**

The tests use `any_instance.stubs` which requires the `mocha` gem. Add to `Gemfile` in the test group:

```ruby
gem "mocha"
```

Then add to `test/test_helper.rb` after `require "shoulda/matchers"`:

```ruby
require "mocha/minitest"
```

Run:

```bash
bundle install
```

**Step 5: Run tests**

```bash
bin/rails test test/jobs/content_review_job_test.rb test/jobs/seo_review_job_test.rb
```

Expected: Tests may fail because `Views::Admin::Articles::ReviewSuggestionsList` doesn't exist yet. The broadcast methods reference it. For now, stub it:

Update both job tests' setup to stub the broadcast:

```ruby
  setup do
    @article = create(:article, :draft)
    @review = create(:article_review, article: @article)
    @user = create(:user)
    Turbo::StreamsChannel.stubs(:broadcast_replace_to)
  end
```

Re-run:

```bash
bin/rails test test/jobs/content_review_job_test.rb test/jobs/seo_review_job_test.rb
```

Expected: All PASS.

**Step 6: Commit**

```bash
git add -A
git commit -m "Add ContentReviewJob and SeoReviewJob with tests"
```

---

### Task 5: Create Reviews Controller and Routes

**Files:**
- Create: `app/controllers/articles/reviews_controller.rb`
- Modify: `config/routes.rb`
- Create: `test/controllers/articles/reviews_controller_test.rb`

**Step 1: Write tests**

Create `test/controllers/articles/reviews_controller_test.rb`:

```ruby
require "test_helper"

class Articles::ReviewsControllerTest < ActionDispatch::IntegrationTest
  context "unauthenticated" do
    should "redirect to sign in" do
      article = create(:article, :draft)
      post review_article_url(slug: article.slug)
      assert_response :redirect
    end
  end

  context "POST #create (authenticated)" do
    setup do
      @user = create(:user)
      sign_in(@user)
      @article = create(:article, :draft)
    end

    should "create an article review and enqueue both jobs" do
      assert_difference("ArticleReview.count", 1) do
        post review_article_url(slug: @article.slug)
      end

      assert_redirected_to edit_article_url(slug: @article.slug, tab: "review")
    end

    should "enqueue content and seo review jobs" do
      assert_enqueued_jobs 2 do
        post review_article_url(slug: @article.slug)
      end
    end
  end

  context "PATCH #update_suggestion (authenticated)" do
    setup do
      @user = create(:user)
      sign_in(@user)
      @article = create(:article, :draft, body: "This is a orginal text.")
      @review = create(:article_review, article: @article)
      @suggestion = create(:review_suggestion, article_review: @review)
    end

    should "accept a suggestion and apply the change" do
      patch article_review_suggestion_url(
        slug: @article.slug,
        id: @suggestion.id
      ), params: { status: "accepted" }

      @suggestion.reload
      @article.reload
      assert_equal "accepted", @suggestion.status
      assert_includes @article.body, "This is an original text."
      assert_response :success
    end

    should "reject a suggestion without modifying the article" do
      original_body = @article.body

      patch article_review_suggestion_url(
        slug: @article.slug,
        id: @suggestion.id
      ), params: { status: "rejected" }

      @suggestion.reload
      @article.reload
      assert_equal "rejected", @suggestion.status
      assert_equal original_body, @article.body
      assert_response :success
    end
  end
end
```

**Step 2: Add routes**

In `config/routes.rb`, inside the `resources :articles` block, add to the `member` block:

```ruby
      post :review, to: "articles/reviews#create"
```

And add a new standalone route for suggestion updates (outside the articles resource):

```ruby
  patch "articles/:slug/review_suggestions/:id", to: "articles/reviews#update_suggestion", as: :article_review_suggestion
```

The full routes file becomes:

```ruby
Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token

  resources :articles, param: :slug, only: [ :index, :new, :create, :edit, :update, :destroy ] do
    member do
      post :publish, to: "articles/publishes#create"
      post :review, to: "articles/reviews#create"
      get :export, to: "articles/exports#create"
    end
    collection do
      post :markdown_preview, to: "articles/markdown_previews#show"
    end
  end

  patch "articles/:slug/review_suggestions/:id", to: "articles/reviews#update_suggestion", as: :article_review_suggestion

  resources :categories, only: [ :index, :create, :destroy ]

  get "up" => "rails/health#show", as: :rails_health_check

  root "articles#index"
end
```

**Step 3: Run tests to verify they fail**

```bash
bin/rails test test/controllers/articles/reviews_controller_test.rb
```

Expected: FAIL (controller doesn't exist).

**Step 4: Implement controller**

Create `app/controllers/articles/reviews_controller.rb`:

```ruby
module Articles
  class ReviewsController < ApplicationController
    def create
      @article = Article.find_by!(slug: params[:slug])
      review = @article.article_reviews.create!

      ContentReviewJob.perform_later(review, Current.user)
      SeoReviewJob.perform_later(review, Current.user)

      redirect_to edit_article_url(slug: @article.slug, tab: "review")
    end

    def update_suggestion
      @article = Article.find_by!(slug: params[:slug])
      @suggestion = ReviewSuggestion.find(params[:id])

      if params[:status] == "accepted"
        apply_suggestion(@suggestion)
        @suggestion.update!(status: "accepted")
      else
        @suggestion.update!(status: "rejected")
      end

      render turbo_stream: turbo_stream.replace(
        "suggestion-#{@suggestion.id}",
        Views::Admin::Articles::ReviewSuggestionCard.new(
          suggestion: @suggestion,
          article: @article
        )
      )
    end

    private

    def apply_suggestion(suggestion)
      article = suggestion.article_review.article
      return unless suggestion.original_text.present?

      case suggestion.category
      when "title"
        article.update!(title: suggestion.suggested_text)
      else
        updated_body = article.body.sub(suggestion.original_text, suggestion.suggested_text)
        article.update!(body: updated_body)
      end
    end
  end
end
```

**Step 5: Run tests**

```bash
bin/rails test test/controllers/articles/reviews_controller_test.rb
```

Expected: Some tests may fail because view components don't exist yet. Stub the turbo_stream render in update_suggestion tests if needed. The create tests should pass.

**Step 6: Commit**

```bash
git add -A
git commit -m "Add reviews controller with create and update_suggestion actions"
```

---

### Task 6: Create Review Tab UI Components

**Files:**
- Create: `app/views/admin/articles/review_tab.rb`
- Create: `app/views/admin/articles/review_suggestions_list.rb`
- Create: `app/views/admin/articles/review_suggestion_card.rb`
- Modify: `app/views/admin/articles/form.rb`
- Modify: `app/components/admin/markdown_preview.rb`

**Step 1: Create ReviewSuggestionCard component**

Create `app/views/admin/articles/review_suggestion_card.rb`:

```ruby
# frozen_string_literal: true

class Views::Admin::Articles::ReviewSuggestionCard < Views::Base
  def initialize(suggestion:, article:)
    @suggestion = suggestion
    @article = article
  end

  def view_template
    div(id: "suggestion-#{@suggestion.id}", class: "border border-border rounded-lg p-4 space-y-3") do
      # Header: category badge + status
      div(class: "flex items-center justify-between") do
        Badge(variant: category_variant) { plain @suggestion.category.capitalize }
        if @suggestion.status != "pending"
          Badge(variant: @suggestion.status == "accepted" ? :green : :gray) do
            plain @suggestion.status.capitalize
          end
        end
      end

      # Explanation
      p(class: "text-sm text-muted-foreground") { plain @suggestion.explanation }

      # Original vs Suggested
      if @suggestion.original_text.present?
        div(class: "space-y-1") do
          div(class: "text-sm") do
            span(class: "font-medium text-destructive") { "- " }
            span(class: "line-through text-destructive/70") { plain @suggestion.original_text }
          end
          div(class: "text-sm") do
            span(class: "font-medium text-green-600 dark:text-green-400") { "+ " }
            span(class: "text-green-600 dark:text-green-400") { plain @suggestion.suggested_text }
          end
        end
      else
        div(class: "text-sm") do
          span(class: "font-medium text-green-600 dark:text-green-400") { "+ " }
          span(class: "text-green-600 dark:text-green-400") { plain @suggestion.suggested_text }
        end
      end

      # Actions (only for pending suggestions)
      if @suggestion.status == "pending"
        div(class: "flex gap-2 pt-1") do
          form(
            action: article_review_suggestion_path(slug: @article.slug, id: @suggestion.id),
            method: "post",
            data: { turbo_frame: "_top" }
          ) do
            input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)
            input(type: "hidden", name: "_method", value: "patch")
            input(type: "hidden", name: "status", value: "accepted")
            Button(type: :submit, variant: :outline, size: :sm) { "Accept" }
          end

          form(
            action: article_review_suggestion_path(slug: @article.slug, id: @suggestion.id),
            method: "post",
            data: { turbo_frame: "_top" }
          ) do
            input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)
            input(type: "hidden", name: "_method", value: "patch")
            input(type: "hidden", name: "status", value: "rejected")
            Button(type: :submit, variant: :ghost, size: :sm, class: "text-muted-foreground") { "Reject" }
          end
        end
      end
    end
  end

  private

  def category_variant
    case @suggestion.category
    when "grammar", "clarity" then :yellow
    when "tone", "structure" then :blue
    when "title", "seo" then :green
    when "summary", "tags" then :gray
    end
  end
end
```

**Step 2: Create ReviewSuggestionsList component**

Create `app/views/admin/articles/review_suggestions_list.rb`:

```ruby
# frozen_string_literal: true

class Views::Admin::Articles::ReviewSuggestionsList < Views::Base
  def initialize(suggestions:, article:)
    @suggestions = suggestions
    @article = article
  end

  def view_template
    if @suggestions.any?
      div(class: "space-y-3") do
        @suggestions.each do |suggestion|
          render Views::Admin::Articles::ReviewSuggestionCard.new(
            suggestion: suggestion,
            article: @article
          )
        end
      end
    else
      p(class: "text-sm text-muted-foreground") { "No suggestions found — your article looks good!" }
    end
  end
end
```

**Step 3: Create ReviewTab component**

Create `app/views/admin/articles/review_tab.rb`:

```ruby
# frozen_string_literal: true

class Views::Admin::Articles::ReviewTab < Views::Base
  def initialize(article:)
    @article = article
    @latest_review = @article.article_reviews.order(created_at: :desc).first
  end

  def view_template
    div(class: "space-y-6 py-4") do
      # Review button
      if @article.persisted?
        div(class: "flex justify-center") do
          form(action: review_article_path(slug: @article.slug), method: "post") do
            input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)
            Button(type: :submit, disabled: review_in_progress?) do
              plain review_in_progress? ? "Review in progress..." : "Review Article"
            end
          end
        end
      else
        p(class: "text-sm text-muted-foreground text-center") { "Save the article first to enable AI review." }
      end

      # Content Review Section
      div do
        Heading(level: 3, class: "mb-3") { "Content Review" }
        p(class: "text-sm text-muted-foreground mb-3") { "Grammar, clarity, tone, and structure" }
        div(id: "content-review-results") do
          if @latest_review
            render_section_status("content")
          else
            p(class: "text-sm text-muted-foreground") { "No review yet." }
          end
        end
      end

      # SEO Review Section
      div do
        Heading(level: 3, class: "mb-3") { "SEO & Metadata Review" }
        p(class: "text-sm text-muted-foreground mb-3") { "Title, SEO, summaries, and tags" }
        div(id: "seo-review-results") do
          if @latest_review
            render_section_status("seo")
          else
            p(class: "text-sm text-muted-foreground") { "No review yet." }
          end
        end
      end
    end
  end

  private

  def review_in_progress?
    @latest_review && (@latest_review.content_status == "pending" || @latest_review.seo_status == "pending")
  end

  def render_section_status(process)
    status = process == "content" ? @latest_review.content_status : @latest_review.seo_status

    case status
    when "pending"
      div(class: "flex items-center gap-2") do
        span(class: "animate-pulse text-sm text-muted-foreground") { "Analyzing..." }
      end
    when "completed"
      suggestions = @latest_review.review_suggestions.where(process: process)
      render Views::Admin::Articles::ReviewSuggestionsList.new(
        suggestions: suggestions,
        article: @article
      )
    when "failed"
      p(class: "text-sm text-destructive") { "Review failed. Please try again." }
    end
  end
end
```

**Step 4: Add Review tab to the article form**

The article form currently has a `MarkdownPreview` component with Write/Preview tabs. We need to add a third "Review" tab. The form dialog currently renders the markdown editor via `render Components::Admin::MarkdownPreview.new(body: @article.body)`.

Modify `app/components/admin/markdown_preview.rb` to accept an optional `article` param and render a Review tab:

```ruby
# frozen_string_literal: true

class Components::Admin::MarkdownPreview < Components::Base
  def initialize(body: "", article: nil)
    @body = body
    @article = article
  end

  def view_template
    div(data: { controller: "markdown-preview" }) do
      Tabs(default: "write") do
        TabsList do
          TabsTrigger(value: "write") { "Write" }
          TabsTrigger(
            value: "preview",
            data: { action: "click->markdown-preview#fetchPreview" }
          ) { "Preview" }
          TabsTrigger(value: "review") { "Review" } if @article&.persisted?
        end

        TabsContent(value: "write") do
          textarea(
            name: "article[body]",
            class: "w-full min-h-[70vh] p-4 pb-2 font-mono text-sm border border-input rounded-lg bg-background text-foreground resize-none focus:outline-none focus:ring-2 focus:ring-ring",
            data: { markdown_preview_target: "input" },
            placeholder: "Write your article in markdown..."
          ) { plain @body }
        end

        TabsContent(value: "preview") do
          div(
            class: "min-h-[70vh] p-4 pb-2 border border-input rounded-lg bg-background prose prose-sm dark:prose-invert max-w-none",
            data: { markdown_preview_target: "preview" }
          ) do
            raw safe(MarkdownRenderer.render(@body)) if @body.present?
          end
        end

        if @article&.persisted?
          TabsContent(value: "review") do
            div(class: "min-h-[70vh] p-4 pb-2 border border-input rounded-lg bg-background overflow-y-auto") do
              render Views::Admin::Articles::ReviewTab.new(article: @article)
            end
          end
        end
      end
    end
  end
end
```

**Step 5: Update the form to pass article to MarkdownPreview**

In `app/views/admin/articles/form.rb`, change line 100 from:

```ruby
        render Components::Admin::MarkdownPreview.new(body: @article.body)
```

To:

```ruby
        render Components::Admin::MarkdownPreview.new(body: @article.body, article: @article)
```

**Step 6: Add turbo_stream_from to the edit form for broadcasts**

In `app/views/admin/articles/form.rb`, add at the beginning of the `form_content` method (after `method = ...`, before the form tag):

```ruby
    turbo_frame_tag("review-stream") do
      turbo_stream_from Current.user if @article.persisted?
    end
```

Wait — Phlex views don't have direct access to `turbo_stream_from`. Let's use the raw tag approach instead. In the `form_content` method, before the form tag, add:

```ruby
    if @article.persisted?
      tag(:"turbo-cable-stream-source",
        channel: "Turbo::StreamsChannel",
        "signed-stream-name": Turbo::StreamsChannel.signed_stream_name(Current.user)
      )
    end
```

Actually, since `Views::Base` inherits from `Components::Base` which includes `Phlex::Rails::Helpers::Routes`, we need to check if turbo stream helpers are available. The simpler approach: add the stream subscription in the layout only when editing. But the layout was cleaned up.

The cleanest approach: add the `turbo-cable-stream-source` tag directly in the review tab component. In `app/views/admin/articles/review_tab.rb`, at the top of `view_template`, add:

```ruby
    # Subscribe to user's Turbo Stream channel for broadcast updates
    tag(:"turbo-cable-stream-source",
      channel: "Turbo::StreamsChannel",
      "signed-stream-name": Turbo::StreamsChannel.signed_stream_name(Current.user)
    ) if @article.persisted?
```

Note: `Current.user` is available because `Components::Base` inherits from `Phlex::HTML` with Rails helpers. If `Current.user` isn't accessible in Phlex views, register it as a value helper in `Components::Base`:

```ruby
register_value_helper :current_user
```

And use `current_user` instead. But `Current.user` should work since it's a thread-local global.

**Step 7: Run all tests**

```bash
bin/rails test
```

Expected: All tests pass. Some review controller tests for `update_suggestion` may need turbo stream response assertions adjusted.

**Step 8: Commit**

```bash
git add -A
git commit -m "Add Review tab UI with suggestion cards and broadcast support"
```

---

### Task 7: Integration Test and Final Verification

**Files:**
- Modify: `test/controllers/articles/reviews_controller_test.rb` (adjust if needed)
- Run: Full CI suite

**Step 1: Run full test suite**

```bash
bin/rails test
```

Fix any failures.

**Step 2: Run rubocop**

```bash
bin/rubocop
```

Fix any offenses.

**Step 3: Run brakeman**

```bash
bin/brakeman --quiet --no-pager
```

Verify no warnings.

**Step 4: Manual smoke test**

1. Start dev server: `bin/dev`
2. Set `GEMINI_API_KEY` env var
3. Create/edit an article with some text
4. Click the "Review" tab
5. Click "Review Article"
6. Wait for suggestions to appear (via broadcast)
7. Accept one suggestion — verify diff shows and change applies
8. Reject one suggestion — verify it's marked rejected

**Step 5: Commit any fixes**

```bash
git add -A
git commit -m "Final adjustments for AI article review feature"
```
