# Blog with Admin Panel — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a single-author blog with markdown editing, scheduled publishing, category filtering, and modal-based Hotwire navigation.

**Architecture:** Single-layout SPA using Hotwire (Turbo Frames for modals and filtering). Auth-guarded admin actions in the same controllers. Phlex views with RubyUI components. Solid Queue for scheduled publish jobs.

**Tech Stack:** Rails 8.1, Phlex, RubyUI, Tailwind CSS v4, Turbo Frames, Stimulus, Redcarpet, Rouge, Solid Queue, ActiveStorage, SQLite3.

---

### Task 1: Add Gem Dependencies

**Files:**
- Modify: `Gemfile`

**Step 1: Add redcarpet and rouge gems**

Add to the Gemfile after the `ruby_ui` gem line:

```ruby
gem "redcarpet", "~> 3.6"
gem "rouge", "~> 4.5"
```

**Step 2: Bundle install**

Run: `bundle install`
Expected: Both gems install successfully.

**Step 3: Commit**

```bash
git add Gemfile Gemfile.lock
git commit -m "Add redcarpet and rouge gems for markdown rendering"
```

---

### Task 2: Generate Authentication

Rails 8 has a built-in auth generator that creates User, Session, and the Authentication concern.

**Step 1: Run the auth generator**

Run: `bin/rails generate authentication`

This creates:
- `app/models/user.rb`
- `app/models/session.rb`
- `app/controllers/sessions_controller.rb`
- `app/controllers/concerns/authentication.rb`
- `app/views/sessions/new.html.erb`
- Migrations for `users` and `sessions` tables

**Step 2: Run migrations**

Run: `bin/rails db:migrate`
Expected: Tables `users` and `sessions` created.

**Step 3: Verify ApplicationController includes Authentication**

Check that `app/controllers/application_controller.rb` now includes:
```ruby
class ApplicationController < ActionController::Base
  include Authentication
  allow_browser versions: :modern
  stale_when_importmap_changes
end
```

If the generator didn't add it, add `include Authentication` manually.

**Step 4: Run tests**

Run: `bin/rails test`
Expected: All generated tests pass.

**Step 5: Commit**

```bash
git add -A
git commit -m "Generate Rails 8 authentication (User, Session, Authentication concern)"
```

---

### Task 3: User Factory and Model Test

**Files:**
- Create: `test/factories/users.rb`
- Create: `test/models/user_test.rb`

**Step 1: Write user factory**

```ruby
# test/factories/users.rb
FactoryBot.define do
  factory :user do
    email_address { "admin@kupo.com" }
    password { "password123" }
  end
end
```

**Step 2: Write user model test**

```ruby
# test/models/user_test.rb
require "test_helper"

class UserTest < ActiveSupport::TestCase
  subject { build(:user) }

  should validate_presence_of(:email_address)
  should validate_uniqueness_of(:email_address)
  should have_secure_password
end
```

**Step 3: Run tests**

Run: `bin/rails test test/models/user_test.rb`
Expected: All pass (User model already exists from generator).

**Step 4: Commit**

```bash
git add test/factories/users.rb test/models/user_test.rb
git commit -m "Add user factory and model tests"
```

---

### Task 4: Category Model (TDD)

**Files:**
- Create: `test/factories/categories.rb`
- Create: `test/models/category_test.rb`
- Create: `app/models/category.rb`
- Create: migration for `categories`

**Step 1: Write category factory**

```ruby
# test/factories/categories.rb
FactoryBot.define do
  factory :category do
    sequence(:name) { |n| "Category #{n}" }
  end
end
```

**Step 2: Write failing category model test**

```ruby
# test/models/category_test.rb
require "test_helper"

class CategoryTest < ActiveSupport::TestCase
  subject { build(:category) }

  should validate_presence_of(:name)
  should validate_uniqueness_of(:name)
  should validate_presence_of(:slug)
  should validate_uniqueness_of(:slug)

  context "slug generation" do
    should "auto-generate slug from name before validation" do
      category = build(:category, name: "Ruby on Rails", slug: nil)
      category.valid?
      assert_equal "ruby-on-rails", category.slug
    end

    should "not overwrite an existing slug" do
      category = build(:category, name: "Ruby", slug: "custom-slug")
      category.valid?
      assert_equal "custom-slug", category.slug
    end
  end

  context "associations" do
    should have_many(:article_categories).dependent(:destroy)
    should have_many(:articles).through(:article_categories)
  end
end
```

**Step 3: Run test to verify it fails**

Run: `bin/rails test test/models/category_test.rb`
Expected: FAIL — table/model doesn't exist.

**Step 4: Generate migration**

Run: `bin/rails generate migration CreateCategories name:string slug:string`

Edit the generated migration:

```ruby
class CreateCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :categories do |t|
      t.string :name, null: false
      t.string :slug, null: false

      t.timestamps
    end

    add_index :categories, :name, unique: true
    add_index :categories, :slug, unique: true
  end
end
```

Run: `bin/rails db:migrate`

**Step 5: Create Category model**

```ruby
# app/models/category.rb
class Category < ApplicationRecord
  has_many :article_categories, dependent: :destroy
  has_many :articles, through: :article_categories

  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true

  before_validation :generate_slug, if: -> { slug.blank? }

  private

  def generate_slug
    self.slug = name&.parameterize
  end
end
```

**Step 6: Run tests**

Run: `bin/rails test test/models/category_test.rb`
Expected: All pass. (The `article_categories` association tests will fail until Task 6 — that's OK, skip those for now or comment them out temporarily.)

**Step 7: Commit**

```bash
git add app/models/category.rb test/factories/categories.rb test/models/category_test.rb db/migrate/*_create_categories.rb db/schema.rb
git commit -m "Add Category model with slug generation, validations, and tests"
```

---

### Task 5: Article Model (TDD)

**Files:**
- Create: `test/factories/articles.rb`
- Create: `test/models/article_test.rb`
- Create: `app/models/article.rb`
- Create: migration for `articles`

**Step 1: Write article factory**

```ruby
# test/factories/articles.rb
FactoryBot.define do
  factory :article do
    sequence(:title) { |n| "Article Title #{n}" }
    body { "# Hello World\n\nThis is a **markdown** article." }
    status { "draft" }

    trait :draft do
      status { "draft" }
      published_at { nil }
    end

    trait :scheduled do
      status { "scheduled" }
      published_at { 1.day.from_now }
    end

    trait :published do
      status { "published" }
      published_at { 1.hour.ago }
    end
  end
end
```

**Step 2: Write failing article model test**

```ruby
# test/models/article_test.rb
require "test_helper"

class ArticleTest < ActiveSupport::TestCase
  subject { build(:article) }

  should validate_presence_of(:title)
  should validate_presence_of(:body)
  should validate_presence_of(:slug)
  should validate_uniqueness_of(:slug)
  should validate_inclusion_of(:status).in_array(%w[draft scheduled published])

  context "slug generation" do
    should "auto-generate slug from title before validation" do
      article = build(:article, title: "My First Post", slug: nil)
      article.valid?
      assert_equal "my-first-post", article.slug
    end

    should "not overwrite an existing slug" do
      article = build(:article, title: "My Post", slug: "custom-slug")
      article.valid?
      assert_equal "custom-slug", article.slug
    end

    should "generate unique slugs for duplicate titles" do
      create(:article, title: "My Post")
      article = build(:article, title: "My Post", slug: nil)
      article.valid?
      assert_match(/\Amy-post-\h+\z/, article.slug)
    end
  end

  context "scopes" do
    setup do
      @draft = create(:article, :draft)
      @scheduled = create(:article, :scheduled)
      @published = create(:article, :published)
    end

    should "return only published articles" do
      assert_equal [@published], Article.published.to_a
    end

    should "return only draft articles" do
      assert_equal [@draft], Article.drafts.to_a
    end

    should "return only scheduled articles" do
      assert_equal [@scheduled], Article.scheduled.to_a
    end

    should "order published articles by published_at desc" do
      older = create(:article, :published, published_at: 2.hours.ago)
      assert_equal [@published, older], Article.published.recent.to_a
    end
  end

  context "associations" do
    should have_many(:article_categories).dependent(:destroy)
    should have_many(:categories).through(:article_categories)
    should have_many_attached(:images)
  end

  context "publishing" do
    should "publish now sets status and published_at" do
      article = create(:article, :draft)
      article.publish_now!

      assert_equal "published", article.status
      assert_not_nil article.published_at
      assert article.published_at <= Time.current
    end

    should "schedule sets status to scheduled with future date" do
      article = create(:article, :draft)
      future = 2.days.from_now
      article.schedule!(future)

      assert_equal "scheduled", article.status
      assert_equal future.to_i, article.published_at.to_i
    end
  end
end
```

**Step 3: Run test to verify it fails**

Run: `bin/rails test test/models/article_test.rb`
Expected: FAIL — table/model doesn't exist.

**Step 4: Generate migration**

Run: `bin/rails generate migration CreateArticles title:string slug:string body:text status:string published_at:datetime`

Edit the generated migration:

```ruby
class CreateArticles < ActiveRecord::Migration[8.1]
  def change
    create_table :articles do |t|
      t.string :title, null: false
      t.string :slug, null: false
      t.text :body, null: false
      t.string :status, null: false, default: "draft"
      t.datetime :published_at

      t.timestamps
    end

    add_index :articles, :slug, unique: true
    add_index :articles, :status
    add_index :articles, [:status, :published_at]
  end
end
```

Run: `bin/rails db:migrate`

**Step 5: Create Article model**

```ruby
# app/models/article.rb
class Article < ApplicationRecord
  has_many :article_categories, dependent: :destroy
  has_many :categories, through: :article_categories
  has_many_attached :images

  validates :title, presence: true
  validates :body, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :status, presence: true, inclusion: { in: %w[draft scheduled published] }

  before_validation :generate_slug, if: -> { slug.blank? }

  scope :published, -> { where(status: "published") }
  scope :drafts, -> { where(status: "draft") }
  scope :scheduled, -> { where(status: "scheduled") }
  scope :recent, -> { order(published_at: :desc) }

  def publish_now!
    update!(status: "published", published_at: Time.current)
  end

  def schedule!(time)
    update!(status: "scheduled", published_at: time)
  end

  private

  def generate_slug
    base_slug = title&.parameterize
    if Article.exists?(slug: base_slug)
      self.slug = "#{base_slug}-#{SecureRandom.hex(4)}"
    else
      self.slug = base_slug
    end
  end
end
```

**Step 6: Run tests**

Run: `bin/rails test test/models/article_test.rb`
Expected: All pass (association tests for article_categories may fail until Task 6).

**Step 7: Commit**

```bash
git add app/models/article.rb test/factories/articles.rb test/models/article_test.rb db/migrate/*_create_articles.rb db/schema.rb
git commit -m "Add Article model with slug generation, scopes, publishing, and tests"
```

---

### Task 6: ArticleCategory Join Table (TDD)

**Files:**
- Create: `app/models/article_category.rb`
- Create: `test/models/article_category_test.rb`
- Create: migration for `article_categories`

**Step 1: Write failing test**

```ruby
# test/models/article_category_test.rb
require "test_helper"

class ArticleCategoryTest < ActiveSupport::TestCase
  subject { build(:article_category) }

  should belong_to(:article)
  should belong_to(:category)

  should "enforce uniqueness of article and category pair" do
    article = create(:article)
    category = create(:category)
    create(:article_category, article: article, category: category)

    duplicate = build(:article_category, article: article, category: category)
    assert_not duplicate.valid?
  end
end
```

Add to factories:

```ruby
# test/factories/article_categories.rb
FactoryBot.define do
  factory :article_category do
    article
    category
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bin/rails test test/models/article_category_test.rb`
Expected: FAIL — table/model doesn't exist.

**Step 3: Generate migration and model**

Run: `bin/rails generate migration CreateArticleCategories article:references category:references`

Edit the generated migration:

```ruby
class CreateArticleCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :article_categories do |t|
      t.references :article, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true

      t.timestamps
    end

    add_index :article_categories, [:article_id, :category_id], unique: true
  end
end
```

Run: `bin/rails db:migrate`

```ruby
# app/models/article_category.rb
class ArticleCategory < ApplicationRecord
  belongs_to :article
  belongs_to :category

  validates :article_id, uniqueness: { scope: :category_id }
end
```

**Step 4: Run tests**

Run: `bin/rails test test/models/article_category_test.rb`
Expected: All pass.

**Step 5: Run all model tests to confirm associations work**

Run: `bin/rails test test/models/`
Expected: All pass (Article and Category association tests should now pass too).

**Step 6: Commit**

```bash
git add app/models/article_category.rb test/models/article_category_test.rb test/factories/article_categories.rb db/migrate/*_create_article_categories.rb db/schema.rb
git commit -m "Add ArticleCategory join table with uniqueness constraint and tests"
```

---

### Task 7: MarkdownRenderer Service (TDD)

**Files:**
- Create: `test/services/markdown_renderer_test.rb`
- Create: `app/services/markdown_renderer.rb`

**Step 1: Write failing test**

```ruby
# test/services/markdown_renderer_test.rb
require "test_helper"

class MarkdownRendererTest < ActiveSupport::TestCase
  setup do
    @renderer = MarkdownRenderer
  end

  should "render basic markdown to HTML" do
    html = @renderer.render("# Hello\n\nWorld")
    assert_includes html, "<h1>Hello</h1>"
    assert_includes html, "<p>World</p>"
  end

  should "render bold and italic" do
    html = @renderer.render("**bold** and *italic*")
    assert_includes html, "<strong>bold</strong>"
    assert_includes html, "<em>italic</em>"
  end

  should "render fenced code blocks with syntax highlighting" do
    markdown = "```ruby\nputs 'hello'\n```"
    html = @renderer.render(markdown)
    assert_includes html, "<pre"
    assert_includes html, "highlight"
  end

  should "render tables" do
    markdown = "| A | B |\n|---|---|\n| 1 | 2 |"
    html = @renderer.render(markdown)
    assert_includes html, "<table>"
  end

  should "autolink URLs" do
    html = @renderer.render("Visit https://example.com")
    assert_includes html, '<a href="https://example.com"'
  end

  should "render strikethrough" do
    html = @renderer.render("~~deleted~~")
    assert_includes html, "<del>deleted</del>"
  end

  should "return empty string for nil input" do
    assert_equal "", @renderer.render(nil)
  end

  should "return empty string for blank input" do
    assert_equal "", @renderer.render("")
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bin/rails test test/services/markdown_renderer_test.rb`
Expected: FAIL — MarkdownRenderer not defined.

**Step 3: Create the services directory and implement**

```ruby
# app/services/markdown_renderer.rb
class MarkdownRenderer
  class HTMLRenderer < Redcarpet::Render::HTML
    include Rouge::Plugins::Redcarpet
  end

  RENDERER = Redcarpet::Markdown.new(
    HTMLRenderer.new(hard_wrap: true, link_attributes: { target: "_blank", rel: "noopener" }),
    fenced_code_blocks: true,
    autolink: true,
    tables: true,
    strikethrough: true,
    no_intra_emphasis: true,
    space_after_headers: true
  )

  def self.render(markdown)
    return "" if markdown.blank?
    RENDERER.render(markdown)
  end
end
```

**Step 4: Run tests**

Run: `bin/rails test test/services/markdown_renderer_test.rb`
Expected: All pass.

**Step 5: Commit**

```bash
git add app/services/markdown_renderer.rb test/services/markdown_renderer_test.rb
git commit -m "Add MarkdownRenderer service with syntax highlighting and tests"
```

---

### Task 8: PublishArticleJob (TDD)

**Files:**
- Create: `test/jobs/publish_article_job_test.rb`
- Create: `app/jobs/publish_article_job.rb`

**Step 1: Write failing test**

```ruby
# test/jobs/publish_article_job_test.rb
require "test_helper"

class PublishArticleJobTest < ActiveSupport::TestCase
  should "publish a scheduled article" do
    article = create(:article, :scheduled, published_at: 1.minute.ago)
    PublishArticleJob.perform_now(article)

    article.reload
    assert_equal "published", article.status
  end

  should "not publish an article that is no longer scheduled" do
    article = create(:article, :draft)
    PublishArticleJob.perform_now(article)

    article.reload
    assert_equal "draft", article.status
  end

  should "not publish an article that is already published" do
    article = create(:article, :published)
    original_published_at = article.published_at
    PublishArticleJob.perform_now(article)

    article.reload
    assert_equal "published", article.status
    assert_equal original_published_at.to_i, article.published_at.to_i
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bin/rails test test/jobs/publish_article_job_test.rb`
Expected: FAIL — PublishArticleJob not defined.

**Step 3: Implement the job**

```ruby
# app/jobs/publish_article_job.rb
class PublishArticleJob < ApplicationJob
  queue_as :default

  def perform(article)
    return unless article.status == "scheduled"
    article.publish_now!
  end
end
```

**Step 4: Run tests**

Run: `bin/rails test test/jobs/publish_article_job_test.rb`
Expected: All pass.

**Step 5: Wire up job enqueueing in Article model**

Add to `app/models/article.rb`:

```ruby
def schedule!(time)
  update!(status: "scheduled", published_at: time)
  PublishArticleJob.set(wait_until: time).perform_later(self)
end
```

**Step 6: Run all tests**

Run: `bin/rails test`
Expected: All pass.

**Step 7: Commit**

```bash
git add app/jobs/publish_article_job.rb test/jobs/publish_article_job_test.rb app/models/article.rb
git commit -m "Add PublishArticleJob with scheduled enqueueing and tests"
```

---

### Task 9: Routes Setup

**Files:**
- Modify: `config/routes.rb`

**Step 1: Define all routes**

```ruby
# config/routes.rb
Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  resources :articles, param: :slug, only: [:index, :show, :new, :create, :edit, :update, :destroy] do
    member do
      post :publish
    end
    collection do
      post :preview
    end
  end

  resources :categories, only: [:index, :create, :destroy]

  root "articles#index"
end
```

Note: The auth generator already added session routes. Keep those.

**Step 2: Verify routes**

Run: `bin/rails routes | grep -E "article|categor|root|session"`
Expected: All defined routes visible.

**Step 3: Commit**

```bash
git add config/routes.rb
git commit -m "Define routes for articles, categories, and root"
```

---

### Task 10: ArticlesController — Public Actions (TDD)

**Files:**
- Create: `test/controllers/articles_controller_test.rb`
- Create: `app/controllers/articles_controller.rb`

**Step 1: Write failing tests for public actions**

```ruby
# test/controllers/articles_controller_test.rb
require "test_helper"

class ArticlesControllerTest < ActionDispatch::IntegrationTest
  context "GET #index" do
    should "show only published articles" do
      published = create(:article, :published)
      draft = create(:article, :draft)
      scheduled = create(:article, :scheduled)

      get root_url
      assert_response :success
      assert_includes response.body, published.title
      assert_not_includes response.body, draft.title
      assert_not_includes response.body, scheduled.title
    end

    should "filter articles by category" do
      category = create(:category, name: "Ruby")
      in_category = create(:article, :published, categories: [category])
      other = create(:article, :published)

      get root_url, params: { category: category.slug }
      assert_response :success
      assert_includes response.body, in_category.title
      assert_not_includes response.body, other.title
    end
  end

  context "GET #show" do
    should "show a published article" do
      article = create(:article, :published)
      get article_url(slug: article.slug)
      assert_response :success
      assert_includes response.body, article.title
    end

    should "return 404 for draft article" do
      article = create(:article, :draft)
      assert_raises(ActiveRecord::RecordNotFound) do
        get article_url(slug: article.slug)
      end
    end

    should "return 404 for scheduled article" do
      article = create(:article, :scheduled)
      assert_raises(ActiveRecord::RecordNotFound) do
        get article_url(slug: article.slug)
      end
    end
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bin/rails test test/controllers/articles_controller_test.rb`
Expected: FAIL — controller doesn't exist.

**Step 3: Implement controller**

```ruby
# app/controllers/articles_controller.rb
class ArticlesController < ApplicationController
  allow_unauthenticated_access only: [:index, :show]

  before_action :set_article, only: [:show, :edit, :update, :destroy, :publish]

  def index
    @articles = Article.published.recent
    @articles = @articles.joins(:categories).where(categories: { slug: params[:category] }) if params[:category].present?
    @categories = Category.all
  end

  def show
  end

  private

  def set_article
    @article = if authenticated?
      Article.find_by!(slug: params[:slug])
    else
      Article.published.find_by!(slug: params[:slug])
    end
  end
end
```

Note: We add only `index` and `show` for now. Admin actions come in Task 11.

**Step 4: Create minimal Phlex views (stubs for controller to render)**

We need basic views for the tests to pass. Create minimal stubs:

```ruby
# app/views/articles/index.rb
class Views::Articles::Index < Views::Base
  def initialize(articles:, categories:, current_category: nil)
    @articles = articles
    @categories = categories
    @current_category = current_category
  end

  def view_template
    div do
      @articles.each do |article|
        div { plain article.title }
      end
    end
  end
end
```

```ruby
# app/views/articles/show.rb
class Views::Articles::Show < Views::Base
  def initialize(article:)
    @article = article
  end

  def view_template
    div do
      h1 { plain @article.title }
    end
  end
end
```

Update controller actions to render Phlex views:

```ruby
def index
  @articles = Article.published.recent
  @articles = @articles.joins(:categories).where(categories: { slug: params[:category] }) if params[:category].present?
  @categories = Category.all
  render Views::Articles::Index.new(articles: @articles, categories: @categories, current_category: params[:category])
end

def show
  render Views::Articles::Show.new(article: @article)
end
```

**Step 5: Run tests**

Run: `bin/rails test test/controllers/articles_controller_test.rb`
Expected: All pass.

**Step 6: Commit**

```bash
git add app/controllers/articles_controller.rb test/controllers/articles_controller_test.rb app/views/articles/
git commit -m "Add ArticlesController with public index and show actions (TDD)"
```

---

### Task 11: ArticlesController — Admin CRUD (TDD)

**Files:**
- Modify: `test/controllers/articles_controller_test.rb`
- Modify: `app/controllers/articles_controller.rb`

**Step 1: Add test helper for authentication**

Create a helper method in `test/test_helper.rb` to sign in during tests:

```ruby
# Add to test/test_helper.rb, inside the ActiveSupport::TestCase class
def sign_in(user)
  post session_url, params: { email_address: user.email_address, password: "password123" }
end
```

**Step 2: Write failing tests for admin actions**

Add to `test/controllers/articles_controller_test.rb`:

```ruby
context "authentication required" do
  should "redirect new to sign in when not authenticated" do
    get new_article_url
    assert_response :redirect
  end

  should "redirect create to sign in when not authenticated" do
    post articles_url, params: { article: { title: "Test", body: "Content" } }
    assert_response :redirect
  end

  should "redirect edit to sign in when not authenticated" do
    article = create(:article, :draft)
    get edit_article_url(slug: article.slug)
    assert_response :redirect
  end

  should "redirect update to sign in when not authenticated" do
    article = create(:article, :draft)
    patch article_url(slug: article.slug), params: { article: { title: "Updated" } }
    assert_response :redirect
  end

  should "redirect destroy to sign in when not authenticated" do
    article = create(:article, :draft)
    delete article_url(slug: article.slug)
    assert_response :redirect
  end
end

context "GET #new (authenticated)" do
  setup do
    @user = create(:user)
    sign_in(@user)
  end

  should "render new article form" do
    get new_article_url
    assert_response :success
  end
end

context "POST #create (authenticated)" do
  setup do
    @user = create(:user)
    sign_in(@user)
  end

  should "create a draft article" do
    assert_difference("Article.count", 1) do
      post articles_url, params: { article: { title: "New Post", body: "# Content", category_ids: [] } }
    end

    article = Article.last
    assert_equal "draft", article.status
    assert_redirected_to article_url(slug: article.slug)
  end

  should "not create article with invalid params" do
    assert_no_difference("Article.count") do
      post articles_url, params: { article: { title: "", body: "" } }
    end
    assert_response :unprocessable_entity
  end
end

context "PATCH #update (authenticated)" do
  setup do
    @user = create(:user)
    sign_in(@user)
    @article = create(:article, :draft)
  end

  should "update the article" do
    patch article_url(slug: @article.slug), params: { article: { title: "Updated Title" } }
    @article.reload
    assert_equal "Updated Title", @article.title
    assert_redirected_to article_url(slug: @article.slug)
  end
end

context "DELETE #destroy (authenticated)" do
  setup do
    @user = create(:user)
    sign_in(@user)
    @article = create(:article, :draft)
  end

  should "destroy the article" do
    assert_difference("Article.count", -1) do
      delete article_url(slug: @article.slug)
    end
    assert_redirected_to root_url
  end
end
```

**Step 3: Run test to verify it fails**

Run: `bin/rails test test/controllers/articles_controller_test.rb`
Expected: FAIL — actions not defined.

**Step 4: Implement admin actions**

Add to `app/controllers/articles_controller.rb`:

```ruby
def new
  @article = Article.new
  @categories = Category.all
  render Views::Admin::Articles::Form.new(article: @article, categories: @categories)
end

def create
  @article = Article.new(article_params)

  if @article.save
    redirect_to article_url(slug: @article.slug)
  else
    @categories = Category.all
    render Views::Admin::Articles::Form.new(article: @article, categories: @categories), status: :unprocessable_entity
  end
end

def edit
  @categories = Category.all
  render Views::Admin::Articles::Form.new(article: @article, categories: @categories)
end

def update
  if @article.update(article_params)
    redirect_to article_url(slug: @article.slug)
  else
    @categories = Category.all
    render Views::Admin::Articles::Form.new(article: @article, categories: @categories), status: :unprocessable_entity
  end
end

def destroy
  @article.destroy!
  redirect_to root_url
end

private

def article_params
  params.require(:article).permit(:title, :body, :slug, category_ids: [])
end
```

Create stub admin form view:

```ruby
# app/views/admin/articles/form.rb
class Views::Admin::Articles::Form < Views::Base
  def initialize(article:, categories:)
    @article = article
    @categories = categories
  end

  def view_template
    div do
      h1 { plain @article.new_record? ? "New Article" : "Edit Article" }
    end
  end
end
```

**Step 5: Run tests**

Run: `bin/rails test test/controllers/articles_controller_test.rb`
Expected: All pass.

**Step 6: Commit**

```bash
git add app/controllers/articles_controller.rb test/controllers/articles_controller_test.rb app/views/admin/
git commit -m "Add ArticlesController admin CRUD actions with auth guards (TDD)"
```

---

### Task 12: ArticlesController — Publish & Preview Actions (TDD)

**Files:**
- Modify: `test/controllers/articles_controller_test.rb`
- Modify: `app/controllers/articles_controller.rb`

**Step 1: Write failing tests**

Add to `test/controllers/articles_controller_test.rb`:

```ruby
context "POST #publish (authenticated)" do
  setup do
    @user = create(:user)
    sign_in(@user)
  end

  should "publish an article immediately" do
    article = create(:article, :draft)
    post publish_article_url(slug: article.slug), params: { publish_action: "now" }

    article.reload
    assert_equal "published", article.status
    assert_not_nil article.published_at
    assert_redirected_to article_url(slug: article.slug)
  end

  should "schedule an article for future publication" do
    article = create(:article, :draft)
    future_time = 2.days.from_now.iso8601
    post publish_article_url(slug: article.slug), params: { publish_action: "schedule", published_at: future_time }

    article.reload
    assert_equal "scheduled", article.status
    assert_redirected_to article_url(slug: article.slug)
  end

  should "require authentication" do
    article = create(:article, :draft)
    post publish_article_url(slug: article.slug), params: { publish_action: "now" }
    assert_response :redirect
  end
end

context "POST #preview (authenticated)" do
  setup do
    @user = create(:user)
    sign_in(@user)
  end

  should "render markdown as HTML" do
    post preview_articles_url, params: { body: "# Hello\n\n**Bold** text" }
    assert_response :success
    assert_includes response.body, "<h1>Hello</h1>"
    assert_includes response.body, "<strong>Bold</strong>"
  end

  should "require authentication" do
    post preview_articles_url, params: { body: "# Hello" }
    assert_response :redirect
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bin/rails test test/controllers/articles_controller_test.rb`
Expected: FAIL — actions not defined.

**Step 3: Implement actions**

Add to `app/controllers/articles_controller.rb`:

```ruby
def publish
  case params[:publish_action]
  when "now"
    @article.publish_now!
  when "schedule"
    @article.schedule!(Time.zone.parse(params[:published_at]))
  end

  redirect_to article_url(slug: @article.slug)
end

def preview
  html = MarkdownRenderer.render(params[:body])
  render html: html.html_safe, layout: false
end
```

Update the `before_action` line:

```ruby
before_action :set_article, only: [:show, :edit, :update, :destroy, :publish]
```

And ensure `publish` and `preview` require auth (they already do since only `index` and `show` allow unauthenticated access).

**Step 4: Run tests**

Run: `bin/rails test test/controllers/articles_controller_test.rb`
Expected: All pass.

**Step 5: Commit**

```bash
git add app/controllers/articles_controller.rb test/controllers/articles_controller_test.rb
git commit -m "Add publish and preview actions to ArticlesController (TDD)"
```

---

### Task 13: CategoriesController (TDD)

**Files:**
- Create: `test/controllers/categories_controller_test.rb`
- Create: `app/controllers/categories_controller.rb`

**Step 1: Write failing tests**

```ruby
# test/controllers/categories_controller_test.rb
require "test_helper"

class CategoriesControllerTest < ActionDispatch::IntegrationTest
  context "authentication required" do
    should "redirect index when not authenticated" do
      get categories_url
      assert_response :redirect
    end

    should "redirect create when not authenticated" do
      post categories_url, params: { category: { name: "Ruby" } }
      assert_response :redirect
    end

    should "redirect destroy when not authenticated" do
      category = create(:category)
      delete category_url(category)
      assert_response :redirect
    end
  end

  context "GET #index (authenticated)" do
    setup do
      @user = create(:user)
      sign_in(@user)
    end

    should "list all categories" do
      category = create(:category, name: "Ruby")
      get categories_url
      assert_response :success
      assert_includes response.body, "Ruby"
    end
  end

  context "POST #create (authenticated)" do
    setup do
      @user = create(:user)
      sign_in(@user)
    end

    should "create a category" do
      assert_difference("Category.count", 1) do
        post categories_url, params: { category: { name: "Ruby" } }
      end
      assert_redirected_to categories_url
    end

    should "not create category with blank name" do
      assert_no_difference("Category.count") do
        post categories_url, params: { category: { name: "" } }
      end
      assert_response :unprocessable_entity
    end
  end

  context "DELETE #destroy (authenticated)" do
    setup do
      @user = create(:user)
      sign_in(@user)
    end

    should "destroy a category" do
      category = create(:category)
      assert_difference("Category.count", -1) do
        delete category_url(category)
      end
      assert_redirected_to categories_url
    end
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bin/rails test test/controllers/categories_controller_test.rb`
Expected: FAIL — controller doesn't exist.

**Step 3: Implement controller**

```ruby
# app/controllers/categories_controller.rb
class CategoriesController < ApplicationController
  def index
    @categories = Category.all
    render Views::Admin::Categories::Index.new(categories: @categories)
  end

  def create
    @category = Category.new(category_params)

    if @category.save
      redirect_to categories_url
    else
      @categories = Category.all
      render Views::Admin::Categories::Index.new(categories: @categories, new_category: @category), status: :unprocessable_entity
    end
  end

  def destroy
    @category = Category.find(params[:id])
    @category.destroy!
    redirect_to categories_url
  end

  private

  def category_params
    params.require(:category).permit(:name)
  end
end
```

Create stub admin categories view:

```ruby
# app/views/admin/categories/index.rb
class Views::Admin::Categories::Index < Views::Base
  def initialize(categories:, new_category: nil)
    @categories = categories
    @new_category = new_category || Category.new
  end

  def view_template
    div do
      h1 { "Manage Categories" }
      @categories.each do |category|
        div { plain category.name }
      end
    end
  end
end
```

**Step 4: Run tests**

Run: `bin/rails test test/controllers/categories_controller_test.rb`
Expected: All pass.

**Step 5: Commit**

```bash
git add app/controllers/categories_controller.rb test/controllers/categories_controller_test.rb app/views/admin/categories/
git commit -m "Add CategoriesController with auth-guarded CRUD and tests"
```

---

### Task 14: Modal Component

**Files:**
- Create: `app/components/modal.rb`

**Step 1: Create reusable modal component**

```ruby
# app/components/modal.rb
class Components::Modal < Components::Base
  def initialize(id: "modal", closable: true)
    @id = id
    @closable = closable
  end

  def view_template(&block)
    div(
      id: @id,
      class: "fixed inset-0 z-50 flex items-center justify-center",
      data: { controller: "modal" }
    ) do
      # Backdrop
      div(
        class: "fixed inset-0 bg-black/50 transition-opacity",
        data: { action: "click->modal#close" }
      )

      # Modal content
      div(class: "relative z-10 w-full max-w-3xl max-h-[90vh] overflow-y-auto bg-background rounded-lg shadow-xl mx-4 p-6") do
        if @closable
          button(
            class: "absolute top-4 right-4 text-muted-foreground hover:text-foreground",
            data: { action: "click->modal#close" }
          ) { "✕" }
        end
        yield if block
      end
    end
  end
end
```

**Step 2: Create Stimulus modal controller**

```javascript
// app/javascript/controllers/modal_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  close() {
    this.element.remove()

    // Restore URL if modal was opened via Turbo
    if (window.history.length > 1) {
      window.history.back()
    }
  }

  // Close on Escape key
  disconnect() {
    document.removeEventListener("keydown", this.handleKeydown)
  }

  connect() {
    this.handleKeydown = (event) => {
      if (event.key === "Escape") this.close()
    }
    document.addEventListener("keydown", this.handleKeydown)
  }
}
```

**Step 3: Commit**

```bash
git add app/components/modal.rb app/javascript/controllers/modal_controller.js
git commit -m "Add reusable Modal component with Stimulus controller"
```

---

### Task 15: Public Phlex Views — Articles Index & Card

**Files:**
- Modify: `app/views/articles/index.rb`
- Create: `app/views/articles/card.rb`
- Create: `app/views/categories/filter.rb`

**Step 1: Build the article card component**

```ruby
# app/views/articles/card.rb
class Views::Articles::Card < Views::Base
  def initialize(article:)
    @article = article
  end

  def view_template
    a(
      href: helpers.article_path(slug: @article.slug),
      class: "block p-6 rounded-lg border border-border hover:border-primary transition-colors",
      data: { turbo_frame: "modal", turbo_action: "advance" }
    ) do
      div(class: "flex items-center gap-2 mb-2") do
        @article.categories.each do |category|
          span(class: "text-xs font-medium px-2 py-1 rounded-full bg-secondary text-secondary-foreground") do
            plain category.name
          end
        end
      end

      h2(class: "text-xl font-semibold text-foreground mb-2") { plain @article.title }

      p(class: "text-sm text-muted-foreground") do
        plain @article.published_at&.strftime("%B %d, %Y")
      end

      p(class: "text-muted-foreground mt-2 line-clamp-3") do
        plain @article.body.truncate(200)
      end
    end
  end
end
```

**Step 2: Build the category filter component**

```ruby
# app/views/categories/filter.rb
class Views::Categories::Filter < Views::Base
  def initialize(categories:, current_category: nil)
    @categories = categories
    @current_category = current_category
  end

  def view_template
    nav(class: "flex flex-wrap gap-2 mb-8") do
      a(
        href: helpers.root_path,
        class: filter_class(nil),
        data: { turbo_frame: "articles" }
      ) { "All" }

      @categories.each do |category|
        a(
          href: helpers.root_path(category: category.slug),
          class: filter_class(category.slug),
          data: { turbo_frame: "articles" }
        ) { plain category.name }
      end
    end
  end

  private

  def filter_class(slug)
    base = "px-4 py-2 rounded-full text-sm font-medium transition-colors"
    if @current_category == slug || (@current_category.nil? && slug.nil?)
      "#{base} bg-primary text-primary-foreground"
    else
      "#{base} bg-secondary text-secondary-foreground hover:bg-accent"
    end
  end
end
```

**Step 3: Update the articles index view**

```ruby
# app/views/articles/index.rb
class Views::Articles::Index < Views::Base
  def initialize(articles:, categories:, current_category: nil)
    @articles = articles
    @categories = categories
    @current_category = current_category
  end

  def view_template
    div(class: "max-w-4xl mx-auto px-4 py-8") do
      h1(class: "text-3xl font-bold text-foreground mb-8") { "Articles" }

      render Views::Categories::Filter.new(categories: @categories, current_category: @current_category)

      turbo_frame_tag("articles") do
        div(class: "space-y-4") do
          if @articles.any?
            @articles.each do |article|
              render Views::Articles::Card.new(article: article)
            end
          else
            p(class: "text-muted-foreground text-center py-12") { "No articles found." }
          end
        end
      end
    end

    turbo_frame_tag("modal")
  end
end
```

Note: `turbo_frame_tag` is a Turbo Rails helper. For Phlex, you may need to use the raw HTML helper or include the Turbo helpers. If Phlex doesn't have `turbo_frame_tag`, use:

```ruby
def turbo_frame_tag(id, &block)
  tag("turbo-frame", id: id, &block)
end
```

Add this method to `Views::Base` or `Components::Base`.

**Step 4: Run tests**

Run: `bin/rails test test/controllers/articles_controller_test.rb`
Expected: All pass.

**Step 5: Commit**

```bash
git add app/views/articles/ app/views/categories/
git commit -m "Add public Phlex views for article list, cards, and category filter"
```

---

### Task 16: Public Phlex Views — Article Show (Modal)

**Files:**
- Modify: `app/views/articles/show.rb`
- Modify: `app/controllers/articles_controller.rb`

**Step 1: Build the article show view (modal version)**

```ruby
# app/views/articles/show.rb
class Views::Articles::Show < Views::Base
  def initialize(article:, modal: false)
    @article = article
    @modal = modal
  end

  def view_template
    if @modal
      turbo_frame_tag("modal") do
        render Components::Modal.new do
          article_content
        end
      end
    else
      div(class: "max-w-3xl mx-auto px-4 py-8") do
        article_content
      end
    end
  end

  private

  def article_content
    article(class: "prose prose-lg dark:prose-invert max-w-none") do
      header(class: "mb-8") do
        div(class: "flex items-center gap-2 mb-4") do
          @article.categories.each do |category|
            span(class: "text-xs font-medium px-2 py-1 rounded-full bg-secondary text-secondary-foreground") do
              plain category.name
            end
          end
        end

        h1(class: "text-3xl font-bold text-foreground") { plain @article.title }

        p(class: "text-sm text-muted-foreground mt-2") do
          plain @article.published_at&.strftime("%B %d, %Y")
        end
      end

      div(class: "article-body") do
        unsafe_raw MarkdownRenderer.render(@article.body)
      end
    end
  end
end
```

**Step 2: Update controller to detect Turbo Frame requests**

In `app/controllers/articles_controller.rb`, update `show`:

```ruby
def show
  modal = turbo_frame_request_id == "modal"
  render Views::Articles::Show.new(article: @article, modal: modal)
end
```

**Step 3: Run tests**

Run: `bin/rails test test/controllers/articles_controller_test.rb`
Expected: All pass.

**Step 4: Commit**

```bash
git add app/views/articles/show.rb app/controllers/articles_controller.rb
git commit -m "Add article show view with modal support for Turbo Frame requests"
```

---

### Task 17: Admin Views — Article Form with Markdown Editor

**Files:**
- Modify: `app/views/admin/articles/form.rb`
- Create: `app/components/admin/markdown_preview.rb`
- Create: `app/components/admin/status_badge.rb`

**Step 1: Build the status badge component**

```ruby
# app/components/admin/status_badge.rb
class Components::Admin::StatusBadge < Components::Base
  def initialize(status:)
    @status = status
  end

  def view_template
    span(class: badge_class) { plain @status.capitalize }
  end

  private

  def badge_class
    base = "text-xs font-medium px-2 py-1 rounded-full"
    case @status
    when "published"
      "#{base} bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200"
    when "scheduled"
      "#{base} bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200"
    when "draft"
      "#{base} bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200"
    end
  end
end
```

**Step 2: Build the markdown preview component**

```ruby
# app/components/admin/markdown_preview.rb
class Components::Admin::MarkdownPreview < Components::Base
  def initialize(body: "")
    @body = body
  end

  def view_template
    div(
      class: "grid grid-cols-2 gap-4 h-[60vh]",
      data: { controller: "markdown-preview" }
    ) do
      # Editor pane
      div(class: "flex flex-col") do
        label(class: "text-sm font-medium text-foreground mb-2") { "Markdown" }
        textarea(
          name: "article[body]",
          class: "flex-1 w-full p-4 font-mono text-sm border border-input rounded-lg bg-background text-foreground resize-none focus:outline-none focus:ring-2 focus:ring-ring",
          data: { markdown_preview_target: "input", action: "input->markdown-preview#update" },
          placeholder: "Write your article in markdown..."
        ) { plain @body }
      end

      # Preview pane
      div(class: "flex flex-col") do
        label(class: "text-sm font-medium text-foreground mb-2") { "Preview" }
        div(
          class: "flex-1 overflow-y-auto p-4 border border-input rounded-lg bg-background prose prose-sm dark:prose-invert max-w-none",
          data: { markdown_preview_target: "preview" }
        ) do
          unsafe_raw MarkdownRenderer.render(@body) if @body.present?
        end
      end
    end
  end
end
```

**Step 3: Build the admin article form view**

```ruby
# app/views/admin/articles/form.rb
class Views::Admin::Articles::Form < Views::Base
  def initialize(article:, categories:)
    @article = article
    @categories = categories
  end

  def view_template
    turbo_frame_tag("modal") do
      render Components::Modal.new do
        form_content
      end
    end
  end

  private

  def form_content
    h1(class: "text-2xl font-bold text-foreground mb-6") do
      plain @article.new_record? ? "New Article" : "Edit Article"
    end

    url = @article.new_record? ? helpers.articles_path : helpers.article_path(slug: @article.slug)
    method = @article.new_record? ? "post" : "patch"

    form_with_tag(url: url, method: method) do
      # Title
      div(class: "mb-4") do
        label(for: "article_title", class: "block text-sm font-medium text-foreground mb-1") { "Title" }
        input(
          type: "text",
          name: "article[title]",
          id: "article_title",
          value: @article.title,
          class: "w-full px-4 py-2 border border-input rounded-lg bg-background text-foreground focus:outline-none focus:ring-2 focus:ring-ring",
          required: true
        )
        render_errors_for(:title)
      end

      # Categories
      div(class: "mb-4") do
        label(class: "block text-sm font-medium text-foreground mb-1") { "Categories" }
        div(class: "flex flex-wrap gap-2") do
          @categories.each do |category|
            label(class: "inline-flex items-center gap-1 cursor-pointer") do
              input(
                type: "checkbox",
                name: "article[category_ids][]",
                value: category.id,
                checked: @article.category_ids.include?(category.id),
                class: "rounded border-input"
              )
              span(class: "text-sm text-foreground") { plain category.name }
            end
          end
          # Hidden field to allow empty category_ids
          input(type: "hidden", name: "article[category_ids][]", value: "")
        end
      end

      # Markdown editor with preview
      div(class: "mb-4") do
        render Components::Admin::MarkdownPreview.new(body: @article.body)
      end

      # Image upload
      div(class: "mb-6", data: { controller: "image-upload" }) do
        label(class: "block text-sm font-medium text-foreground mb-1") { "Upload Image" }
        input(
          type: "file",
          accept: "image/*",
          class: "text-sm text-muted-foreground",
          data: { image_upload_target: "input", action: "change->image-upload#upload" }
        )
      end

      # Submit
      div(class: "flex justify-end gap-4") do
        button(
          type: "submit",
          class: "px-6 py-2 bg-primary text-primary-foreground rounded-lg hover:bg-primary/90 transition-colors"
        ) { plain @article.new_record? ? "Create Article" : "Update Article" }
      end
    end
  end

  def form_with_tag(url:, method:, &block)
    actual_method = method == "patch" ? "post" : method
    form(action: url, method: actual_method, class: "space-y-4") do
      input(type: "hidden", name: "authenticity_token", value: helpers.form_authenticity_token)
      input(type: "hidden", name: "_method", value: method) if method == "patch"
      yield
    end
  end

  def render_errors_for(field)
    return unless @article.errors[field].any?
    @article.errors[field].each do |error|
      p(class: "text-sm text-destructive mt-1") { plain error }
    end
  end
end
```

**Step 4: Run tests**

Run: `bin/rails test`
Expected: All pass.

**Step 5: Commit**

```bash
git add app/views/admin/articles/form.rb app/components/admin/
git commit -m "Add admin article form with markdown editor and status badge components"
```

---

### Task 18: Admin Views — Article Index & Categories

**Files:**
- Create: `app/views/admin/articles/index.rb`
- Modify: `app/views/admin/categories/index.rb`

**Step 1: Build admin articles index**

This view is rendered when an authenticated user visits the root. Update the controller to serve a different view for admins.

Modify `ArticlesController#index`:

```ruby
def index
  @categories = Category.all

  if authenticated?
    @articles = Article.recent
    @articles = @articles.joins(:categories).where(categories: { slug: params[:category] }) if params[:category].present?
    @articles = @articles.where(status: params[:status]) if params[:status].present?
    render Views::Admin::Articles::Index.new(articles: @articles, categories: @categories, current_category: params[:category])
  else
    @articles = Article.published.recent
    @articles = @articles.joins(:categories).where(categories: { slug: params[:category] }) if params[:category].present?
    render Views::Articles::Index.new(articles: @articles, categories: @categories, current_category: params[:category])
  end
end
```

Note: `authenticated?` may need to be defined. Check the generated Authentication concern — if it provides `Current.session`, you can define:

```ruby
def authenticated?
  Current.session.present?
end
helper_method :authenticated?
```

Build admin articles index view:

```ruby
# app/views/admin/articles/index.rb
class Views::Admin::Articles::Index < Views::Base
  def initialize(articles:, categories:, current_category: nil)
    @articles = articles
    @categories = categories
    @current_category = current_category
  end

  def view_template
    div(class: "max-w-4xl mx-auto px-4 py-8") do
      div(class: "flex items-center justify-between mb-8") do
        h1(class: "text-3xl font-bold text-foreground") { "Articles" }

        div(class: "flex gap-2") do
          a(
            href: helpers.categories_path,
            class: "px-4 py-2 text-sm border border-input rounded-lg hover:bg-accent transition-colors"
          ) { "Manage Categories" }

          a(
            href: helpers.new_article_path,
            class: "px-4 py-2 text-sm bg-primary text-primary-foreground rounded-lg hover:bg-primary/90 transition-colors",
            data: { turbo_frame: "modal" }
          ) { "New Article" }
        end
      end

      render Views::Categories::Filter.new(categories: @categories, current_category: @current_category)

      # Status filter
      nav(class: "flex gap-2 mb-4") do
        %w[all draft scheduled published].each do |status|
          params_hash = status == "all" ? {} : { status: status }
          params_hash[:category] = @current_category if @current_category
          a(
            href: helpers.root_path(**params_hash),
            class: "text-sm text-muted-foreground hover:text-foreground"
          ) { plain status.capitalize }
        end
      end

      turbo_frame_tag("articles") do
        div(class: "space-y-4") do
          @articles.each do |article|
            admin_article_card(article)
          end
        end
      end
    end

    turbo_frame_tag("modal")
  end

  private

  def admin_article_card(article)
    div(class: "flex items-center justify-between p-4 rounded-lg border border-border") do
      a(
        href: helpers.article_path(slug: article.slug),
        class: "flex-1",
        data: { turbo_frame: "modal", turbo_action: "advance" }
      ) do
        div(class: "flex items-center gap-3") do
          render Components::Admin::StatusBadge.new(status: article.status)
          h2(class: "text-lg font-medium text-foreground") { plain article.title }
        end
        p(class: "text-sm text-muted-foreground mt-1") do
          if article.published_at
            plain "#{article.status == 'scheduled' ? 'Scheduled for' : 'Published'} #{article.published_at.strftime('%B %d, %Y at %H:%M')}"
          else
            plain "Draft"
          end
        end
      end

      div(class: "flex items-center gap-2") do
        a(
          href: helpers.edit_article_path(slug: article.slug),
          class: "text-sm text-muted-foreground hover:text-foreground",
          data: { turbo_frame: "modal" }
        ) { "Edit" }

        button(
          formaction: helpers.article_path(slug: article.slug),
          formmethod: "post",
          name: "_method",
          value: "delete",
          class: "text-sm text-destructive hover:text-destructive/80",
          data: { turbo_confirm: "Are you sure you want to delete this article?" }
        ) { "Delete" }
      end
    end
  end
end
```

**Step 2: Update admin categories index**

```ruby
# app/views/admin/categories/index.rb
class Views::Admin::Categories::Index < Views::Base
  def initialize(categories:, new_category: nil)
    @categories = categories
    @new_category = new_category || Category.new
  end

  def view_template
    turbo_frame_tag("modal") do
      render Components::Modal.new do
        h1(class: "text-2xl font-bold text-foreground mb-6") { "Manage Categories" }

        # New category form
        form(action: helpers.categories_path, method: "post", class: "flex gap-2 mb-6") do
          input(type: "hidden", name: "authenticity_token", value: helpers.form_authenticity_token)
          input(
            type: "text",
            name: "category[name]",
            value: @new_category.name,
            placeholder: "New category name",
            class: "flex-1 px-4 py-2 border border-input rounded-lg bg-background text-foreground focus:outline-none focus:ring-2 focus:ring-ring",
            required: true
          )
          button(
            type: "submit",
            class: "px-4 py-2 bg-primary text-primary-foreground rounded-lg hover:bg-primary/90 transition-colors"
          ) { "Add" }
        end

        # Category list
        div(class: "space-y-2") do
          @categories.each do |category|
            div(class: "flex items-center justify-between p-3 rounded-lg border border-border") do
              span(class: "text-foreground") { plain category.name }
              button(
                formaction: helpers.category_path(category),
                formmethod: "post",
                name: "_method",
                value: "delete",
                class: "text-sm text-destructive hover:text-destructive/80",
                data: { turbo_confirm: "Delete #{category.name}?" }
              ) { "Delete" }
            end
          end
        end
      end
    end
  end
end
```

**Step 3: Run tests**

Run: `bin/rails test`
Expected: All pass.

**Step 4: Commit**

```bash
git add app/views/admin/ app/controllers/articles_controller.rb
git commit -m "Add admin views for articles index and categories management"
```

---

### Task 19: Stimulus Controllers — Markdown Preview & Image Upload

**Files:**
- Create: `app/javascript/controllers/markdown_preview_controller.js`
- Create: `app/javascript/controllers/image_upload_controller.js`
- Modify: `config/importmap.rb` (if needed for ActiveStorage direct upload)

**Step 1: Create markdown preview Stimulus controller**

```javascript
// app/javascript/controllers/markdown_preview_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "preview"]

  connect() {
    this.timeout = null
  }

  update() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      this.fetchPreview()
    }, 300)
  }

  async fetchPreview() {
    const body = this.inputTarget.value
    if (!body.trim()) {
      this.previewTarget.innerHTML = ""
      return
    }

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    const response = await fetch("/articles/preview", {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        "X-CSRF-Token": csrfToken,
      },
      body: `body=${encodeURIComponent(body)}`,
    })

    if (response.ok) {
      const html = await response.text()
      this.previewTarget.innerHTML = html
    }
  }
}
```

**Step 2: Create image upload Stimulus controller**

```javascript
// app/javascript/controllers/image_upload_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  async upload(event) {
    const file = event.target.files[0]
    if (!file) return

    const formData = new FormData()
    formData.append("file", file)

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

    // Use ActiveStorage direct upload endpoint
    const response = await fetch("/rails/active_storage/direct_uploads", {
      method: "POST",
      headers: {
        "X-CSRF-Token": csrfToken,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        blob: {
          filename: file.name,
          content_type: file.type,
          byte_size: file.size,
          checksum: await this.computeChecksum(file),
        },
      }),
    })

    if (response.ok) {
      const blob = await response.json()
      const url = `/rails/active_storage/blobs/redirect/${blob.signed_id}/${blob.filename}`
      this.insertMarkdownImage(file.name, url)
      await this.uploadToSignedUrl(blob.direct_upload.url, blob.direct_upload.headers, file)
    }
  }

  insertMarkdownImage(name, url) {
    const textarea = document.querySelector('[data-markdown-preview-target="input"]')
    if (!textarea) return

    const imageTag = `![${name}](${url})`
    const start = textarea.selectionStart
    const before = textarea.value.substring(0, start)
    const after = textarea.value.substring(textarea.selectionEnd)

    textarea.value = `${before}${imageTag}${after}`
    textarea.dispatchEvent(new Event("input"))
  }

  async uploadToSignedUrl(url, headers, file) {
    await fetch(url, {
      method: "PUT",
      headers: headers,
      body: file,
    })
  }

  async computeChecksum(file) {
    const buffer = await file.arrayBuffer()
    const hashBuffer = await crypto.subtle.digest("SHA-256", buffer)
    return btoa(String.fromCharCode(...new Uint8Array(hashBuffer)))
  }
}
```

Note: ActiveStorage direct upload may need its own JS. Check if `@rails/activestorage` is available via importmap. If not, add to `config/importmap.rb`:

```ruby
pin "@rails/activestorage", to: "activestorage.esm.js"
```

And import it in `app/javascript/application.js`:

```javascript
import * as ActiveStorage from "@rails/activestorage"
ActiveStorage.start()
```

The image upload controller above is a simplified version. For production, consider using ActiveStorage's built-in direct upload JS instead.

**Step 3: Commit**

```bash
git add app/javascript/controllers/markdown_preview_controller.js app/javascript/controllers/image_upload_controller.js config/importmap.rb app/javascript/application.js
git commit -m "Add Stimulus controllers for markdown preview and image upload"
```

---

### Task 20: Application Layout Update

**Files:**
- Modify: `app/views/layouts/application.html.erb`

**Step 1: Update layout with header and navigation**

The layout needs a header with site title, auth links, and the main content area. Since we're using Phlex for views but the layout is still ERB, update it:

```erb
<!DOCTYPE html>
<html>
  <head>
    <title>KUPO</title>
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <meta name="csrf-token" content="<%= form_authenticity_token %>">
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>
    <%= stylesheet_link_tag "tailwind", "data-turbo-track": "reload" %>
    <%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
    <%= javascript_importmap_tags %>
  </head>

  <body class="min-h-screen bg-background text-foreground">
    <header class="border-b border-border">
      <div class="max-w-4xl mx-auto px-4 py-4 flex items-center justify-between">
        <a href="/" class="text-xl font-bold text-foreground hover:text-primary transition-colors">
          KUPO
        </a>

        <nav class="flex items-center gap-4">
          <% if authenticated? %>
            <%= button_to "Sign out", session_path(Current.session), method: :delete, class: "text-sm text-muted-foreground hover:text-foreground" %>
          <% else %>
            <a href="/session/new" class="text-sm text-muted-foreground hover:text-foreground">Sign in</a>
          <% end %>
        </nav>
      </div>
    </header>

    <main>
      <%= yield %>
    </main>
  </body>
</html>
```

Note: Adjust `authenticated?` and session paths to match what the Rails 8 auth generator created. Check the generated routes for exact path helpers.

**Step 2: Run tests**

Run: `bin/rails test`
Expected: All pass.

**Step 3: Commit**

```bash
git add app/views/layouts/application.html.erb
git commit -m "Update application layout with header, auth links, and content area"
```

---

### Task 21: Seed Data

**Files:**
- Modify: `db/seeds.rb`

**Step 1: Write seed data**

```ruby
# db/seeds.rb
puts "Creating admin user..."
User.find_or_create_by!(email_address: "admin@kupo.com") do |user|
  user.password = "password123"
end

puts "Creating categories..."
categories = %w[Ruby Rails JavaScript DevOps].map do |name|
  Category.find_or_create_by!(name: name)
end

puts "Creating sample articles..."
[
  {
    title: "Getting Started with Ruby on Rails 8",
    body: "# Getting Started with Rails 8\n\nRails 8 brings the **Solid** stack...\n\n## What's New\n\n- Solid Queue replaces Redis for jobs\n- Solid Cache for caching\n- Solid Cable for WebSockets\n\n```ruby\nrails new myapp\n```\n\nEnjoy building!",
    status: "published",
    published_at: 3.days.ago,
    categories: [categories[0], categories[1]]
  },
  {
    title: "Understanding Hotwire and Turbo",
    body: "# Hotwire and Turbo\n\nHotwire is the default frontend approach in Rails...\n\n## Turbo Frames\n\nTurbo Frames allow you to update parts of a page without a full reload.\n\n## Turbo Streams\n\nFor real-time updates over WebSocket.",
    status: "published",
    published_at: 1.day.ago,
    categories: [categories[1], categories[2]]
  },
  {
    title: "Draft: Advanced Ruby Patterns",
    body: "# Advanced Ruby Patterns\n\nThis is a draft article about metaprogramming...",
    status: "draft",
    published_at: nil,
    categories: [categories[0]]
  }
].each do |attrs|
  cats = attrs.delete(:categories)
  article = Article.find_or_create_by!(title: attrs[:title]) do |a|
    a.assign_attributes(attrs)
  end
  article.categories = cats
end

puts "Seed complete!"
```

**Step 2: Run seeds**

Run: `bin/rails db:seed`
Expected: Admin user, categories, and sample articles created.

**Step 3: Commit**

```bash
git add db/seeds.rb
git commit -m "Add seed data with admin user, categories, and sample articles"
```

---

### Task 22: Run Full Test Suite & Linting

**Step 1: Run all tests**

Run: `bin/rails test`
Expected: All tests pass, zero failures.

**Step 2: Run RuboCop**

Run: `bundle exec rubocop`
Fix any offenses.

**Step 3: Run Brakeman**

Run: `bundle exec brakeman --no-pager --quiet`
Address any warnings (especially around `html_safe` in markdown rendering — may need to note this is intentional for rendered markdown from admin input only).

**Step 4: Commit any fixes**

```bash
git add -A
git commit -m "Fix linting and security warnings"
```

---

### Task 23: System Tests

**Files:**
- Create: `test/system/articles_test.rb`

**Step 1: Write system tests**

```ruby
# test/system/articles_test.rb
require "application_system_test_case"

class ArticlesTest < ApplicationSystemTestCase
  setup do
    @user = create(:user)
    @category = create(:category, name: "Ruby")
    @published = create(:article, :published, title: "Published Article", categories: [@category])
    @draft = create(:article, :draft, title: "Draft Article")
  end

  test "visitor sees published articles" do
    visit root_url
    assert_text "Published Article"
    assert_no_text "Draft Article"
  end

  test "visitor can filter by category" do
    other = create(:article, :published, title: "Untagged Article")
    visit root_url
    click_on "Ruby"
    assert_text "Published Article"
    assert_no_text "Untagged Article"
  end

  test "visitor can view article in modal" do
    visit root_url
    click_on "Published Article"
    assert_selector "[data-controller='modal']"
    assert_text "Published Article"
  end

  test "admin can create a new article" do
    sign_in_as(@user)
    visit root_url
    click_on "New Article"

    fill_in "article_title", with: "My New Article"
    # Fill in the markdown textarea
    find('[data-markdown-preview-target="input"]').set("# Hello World\n\nThis is a test.")
    click_on "Create Article"

    assert_text "My New Article"
  end

  test "admin can publish an article" do
    sign_in_as(@user)
    visit root_url
    # Navigate to draft article and publish
    # Implementation depends on final UI
  end

  private

  def sign_in_as(user)
    visit new_session_url
    fill_in "email_address", with: user.email_address
    fill_in "password", with: "password123"
    click_on "Sign in"
  end
end
```

**Step 2: Run system tests**

Run: `bin/rails test:system`
Expected: All pass.

**Step 3: Commit**

```bash
git add test/system/articles_test.rb
git commit -m "Add system tests for public browsing, filtering, and admin article creation"
```

---

## Task Dependency Order

```
Task 1 (gems)
  → Task 2 (auth generator)
    → Task 3 (user factory/tests)
Task 4 (category model) ─┐
Task 5 (article model) ──┤
  → Task 6 (join table) ─┤
    → Task 7 (markdown service)
    → Task 8 (publish job)
    → Task 9 (routes)
      → Task 10 (public controller)
        → Task 11 (admin CRUD)
          → Task 12 (publish/preview)
      → Task 13 (categories controller)
      → Task 14 (modal component)
      → Task 15 (public views)
        → Task 16 (article show modal)
      → Task 17 (admin form views)
        → Task 18 (admin index views)
      → Task 19 (stimulus controllers)
      → Task 20 (layout update)
    → Task 21 (seed data)
→ Task 22 (full test suite + lint)
  → Task 23 (system tests)
```

## Key References

- **Design doc**: `docs/plans/2026-03-02-blog-with-admin-panel-design.md`
- **Phlex views guide**: Components extend `Components::Base` (which includes RubyUI). Views extend `Views::Base`.
- **Tailwind tokens**: Defined in `app/assets/tailwind/application.css` — use `primary`, `secondary`, `muted`, `accent`, `destructive`, `foreground`, `background`, `border`, `input`, `ring`.
- **Auth concern**: Generated at `app/controllers/concerns/authentication.rb`. Provides `allow_unauthenticated_access`, `authenticated?`, `Current.session`.
- **Solid Queue**: In-process with Puma. Jobs enqueued via `perform_later` with `set(wait_until:)` for scheduling.
- **ActiveStorage**: Configured in `config/storage.yml`. Local disk for dev, S3 for production.
