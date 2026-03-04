# Personal Notebook Transformation — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Transform the KUPO blog into a private personal notebook requiring admin login, with article preview and markdown export.

**Architecture:** Remove all unauthenticated access to articles. Merge public/admin views into a single authenticated experience. Add preview (read-only rendered view) and export (markdown download) member routes on articles.

**Tech Stack:** Rails 8.1, Phlex views, Minitest + Shoulda, FactoryBot

---

### Task 1: Lock down authentication — remove public access

**Files:**
- Modify: `app/controllers/articles_controller.rb:2` (remove `allow_unauthenticated_access`)
- Modify: `app/controllers/articles_controller.rb:76-81` (simplify `set_article`)

**Step 1: Update controller tests for authentication lockdown**

In `test/controllers/articles_controller_test.rb`, replace the existing public index and show tests (lines 4-47) with tests that verify unauthenticated users are redirected:

```ruby
context "GET #index (unauthenticated)" do
  should "redirect to sign in" do
    get root_url
    assert_response :redirect
  end
end

context "GET #show (unauthenticated)" do
  should "redirect to sign in" do
    article = create(:article, :draft)
    get article_url(slug: article.slug)
    assert_response :redirect
  end
end
```

Also add an authenticated index test inside a new context:

```ruby
context "GET #index (authenticated)" do
  setup do
    @user = create(:user)
    sign_in(@user)
  end

  should "show all articles regardless of status" do
    published = create(:article, :published)
    draft = create(:article, :draft)
    scheduled = create(:article, :scheduled)

    get root_url
    assert_response :success
    assert_includes response.body, published.title
    assert_includes response.body, draft.title
    assert_includes response.body, scheduled.title
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
```

**Step 2: Run tests to verify they fail**

Run: `bin/rails test test/controllers/articles_controller_test.rb`
Expected: New unauthenticated redirect tests FAIL (index/show still return 200)

**Step 3: Remove unauthenticated access from controller**

In `app/controllers/articles_controller.rb`:
- Delete line 2: `allow_unauthenticated_access only: [ :index, :show ]`
- Simplify `set_article` to always find any article (remove published-only branch):

```ruby
def set_article
  @article = Article.find_by!(slug: params[:slug])
end
```

**Step 4: Run tests to verify they pass**

Run: `bin/rails test test/controllers/articles_controller_test.rb`
Expected: All PASS

**Step 5: Commit**

```bash
git add app/controllers/articles_controller.rb test/controllers/articles_controller_test.rb
git commit -m "Lock down all article routes to require authentication"
```

---

### Task 2: Simplify ArticlesQuery — remove public/authenticated split

**Files:**
- Modify: `app/queries/articles_query.rb`
- Modify: `test/queries/articles_query_test.rb`

**Step 1: Update query tests**

Replace the entire test file `test/queries/articles_query_test.rb` with:

```ruby
require "test_helper"

class ArticlesQueryTest < ActiveSupport::TestCase
  setup do
    @category = create(:category, name: "Ruby")
    @published = create(:article, :published, categories: [@category])
    @draft = create(:article, :draft)
    @scheduled = create(:article, :scheduled)
  end

  should "return all articles ordered by most recent" do
    result = ArticlesQuery.new(params: {}).call
    assert_includes result, @published
    assert_includes result, @draft
    assert_includes result, @scheduled
  end

  should "filter by category" do
    other = create(:article, :published)

    result = ArticlesQuery.new(params: { category: @category.slug }).call

    assert_includes result, @published
    assert_not_includes result, other
  end

  should "filter by status" do
    result = ArticlesQuery.new(params: { status: "draft" }).call

    assert_not_includes result, @published
    assert_includes result, @draft
    assert_not_includes result, @scheduled
  end

  should "filter by category and status combined" do
    draft_in_category = create(:article, :draft, categories: [@category])

    result = ArticlesQuery.new(params: { category: @category.slug, status: "draft" }).call

    assert_equal [draft_in_category], result.to_a
  end
end
```

**Step 2: Run tests to verify they fail**

Run: `bin/rails test test/queries/articles_query_test.rb`
Expected: FAIL (constructor still requires `authenticated:` keyword)

**Step 3: Simplify the query**

Replace `app/queries/articles_query.rb`:

```ruby
class ArticlesQuery
  def initialize(params:)
    @category = params[:category]
    @status = params[:status]
  end

  def call
    scope = Article.recent
    scope = filter_by_category(scope)
    scope = filter_by_status(scope)
    scope
  end

  private

  def filter_by_category(scope)
    return scope unless @category.present?

    scope.joins(:categories).where(categories: { slug: @category })
  end

  def filter_by_status(scope)
    return scope unless @status.present?

    scope.where(status: @status)
  end
end
```

**Step 4: Update controller call site**

In `app/controllers/articles_controller.rb`, update the `index` action to remove `authenticated:` kwarg and always render the admin index:

```ruby
def index
  @categories = Category.all
  @articles = ArticlesQuery.new(params: params).call

  render Views::Admin::Articles::Index.new(articles: @articles, categories: @categories, current_category: params[:category])
end
```

**Step 5: Run tests to verify they pass**

Run: `bin/rails test test/queries/articles_query_test.rb test/controllers/articles_controller_test.rb`
Expected: All PASS

**Step 6: Commit**

```bash
git add app/queries/articles_query.rb test/queries/articles_query_test.rb app/controllers/articles_controller.rb
git commit -m "Simplify ArticlesQuery to always return all articles"
```

---

### Task 3: Delete public view files

**Files:**
- Delete: `app/views/articles/index.rb`
- Delete: `app/views/articles/show.rb`
- Delete: `app/views/articles/card.rb`
- Delete: `app/views/categories/filter.rb`

**Step 1: Delete the public view files**

```bash
git rm app/views/articles/index.rb app/views/articles/show.rb app/views/articles/card.rb app/views/categories/filter.rb
```

**Step 2: Update admin index to inline the category filter**

The admin index at `app/views/admin/articles/index.rb:30` currently renders `Views::Categories::Filter`. Replace that line with an inline category filter nav:

```ruby
# Category filter
nav(class: "flex flex-wrap gap-2 mb-4") do
  a(
    href: helpers.root_path(status: params[:status]),
    class: filter_class(nil),
    data: { turbo_frame: "articles" }
  ) { "All" }

  @categories.each do |category|
    a(
      href: helpers.root_path(category: category.slug, status: params[:status]),
      class: filter_class(category.slug),
      data: { turbo_frame: "articles" }
    ) { plain category.name }
  end
end
```

Also add the `filter_class` private method and accept `params` in the initializer:

Add to initializer: `current_status: nil` parameter, and store as `@current_status`.
Pass `params` from the controller so the view can access status for filter links.

Actually, a simpler approach: just pass `current_status` from the controller and use it. Update the view's initializer to accept `current_status: nil` and use it in the status filter links.

Update the controller index action:

```ruby
def index
  @categories = Category.all
  @articles = ArticlesQuery.new(params: params).call

  render Views::Admin::Articles::Index.new(
    articles: @articles,
    categories: @categories,
    current_category: params[:category],
    current_status: params[:status]
  )
end
```

Update `Views::Admin::Articles::Index` initializer:

```ruby
def initialize(articles:, categories:, current_category: nil, current_status: nil)
  @articles = articles
  @categories = categories
  @current_category = current_category
  @current_status = current_status
end
```

Replace the category filter render (line 30) with the inline nav, and update the status filter links (lines 33-42) to preserve category param:

```ruby
# Category filter
nav(class: "flex flex-wrap gap-2 mb-4") do
  status_params = @current_status ? { status: @current_status } : {}
  a(
    href: helpers.root_path(**status_params),
    class: category_filter_class(nil),
    data: { turbo_frame: "articles" }
  ) { "All" }

  @categories.each do |category|
    a(
      href: helpers.root_path(category: category.slug, **status_params),
      class: category_filter_class(category.slug),
      data: { turbo_frame: "articles" }
    ) { plain category.name }
  end
end

# Status filter
nav(class: "flex gap-2 mb-4") do
  %w[all draft scheduled published].each do |status|
    params_hash = status == "all" ? {} : { status: status }
    params_hash[:category] = @current_category if @current_category
    a(
      href: helpers.root_path(**params_hash),
      class: status_filter_class(status),
    ) { plain status.capitalize }
  end
end
```

Add to the private section:

```ruby
def category_filter_class(slug)
  base = "px-4 py-2 rounded-full text-sm font-medium transition-colors"
  if @current_category == slug || (@current_category.nil? && slug.nil?)
    "#{base} bg-primary text-primary-foreground"
  else
    "#{base} bg-secondary text-secondary-foreground hover:bg-accent"
  end
end

def status_filter_class(status)
  base = "text-sm transition-colors"
  current = @current_status || "all"
  if current == status
    "#{base} text-foreground font-medium"
  else
    "#{base} text-muted-foreground hover:text-foreground"
  end
end
```

**Step 3: Run all tests**

Run: `bin/rails test`
Expected: All PASS (no references to deleted view classes remain)

**Step 4: Commit**

```bash
git add -A
git commit -m "Remove public views and inline category filter into admin index"
```

---

### Task 4: Update the article show action to redirect to preview

**Files:**
- Modify: `app/controllers/articles_controller.rb`
- Modify: `config/routes.rb`

**Step 1: Write tests for the preview action**

Add to `test/controllers/articles_controller_test.rb`:

```ruby
context "GET #preview (authenticated)" do
  setup do
    @user = create(:user)
    sign_in(@user)
    @article = create(:article, :draft)
  end

  should "render the article preview" do
    get preview_article_url(slug: @article.slug)
    assert_response :success
    assert_includes response.body, @article.title
  end
end

context "GET #preview (unauthenticated)" do
  should "redirect to sign in" do
    article = create(:article, :draft)
    get preview_article_url(slug: article.slug)
    assert_response :redirect
  end
end
```

**Step 2: Run tests to verify they fail**

Run: `bin/rails test test/controllers/articles_controller_test.rb`
Expected: FAIL (no route for preview)

**Step 3: Add preview route and controller action**

In `config/routes.rb`, add `preview` as a member GET action:

```ruby
resources :articles, param: :slug, only: [:index, :new, :create, :edit, :update, :destroy] do
  member do
    post :publish
    get :preview
    get :export
  end
  collection do
    post :markdown_preview
  end
end
```

Note: Rename the existing `show` action. Since we're removing the public show, remove `:show` from the `only` list. The `preview` member route replaces it. Update redirect targets throughout the controller from `article_url` to `preview_article_url`.

In `app/controllers/articles_controller.rb`, replace the `show` action with a `preview` action:

```ruby
def preview
  render Views::Articles::Preview.new(article: @article)
end
```

Update `before_action :set_article` to include `:preview` and `:export` instead of `:show`:

```ruby
before_action :set_article, only: [:edit, :update, :destroy, :publish, :preview, :export]
```

Update all `article_url(slug:)` redirects to `preview_article_url(slug:)`:
- In `create`: `redirect_to preview_article_url(slug: @article.slug)`
- In `update`: `redirect_to preview_article_url(slug: @article.slug)`
- In `publish`: `redirect_to preview_article_url(slug: @article.slug)`

Also rename `preview` (the existing markdown preview collection action at line 69-72) to `markdown_preview`:

```ruby
def markdown_preview
  html = MarkdownRenderer.render(params[:body])
  render html: html.html_safe, layout: false
end
```

**Step 4: Create the Preview view**

Create `app/views/articles/preview.rb`:

```ruby
# frozen_string_literal: true

class Views::Articles::Preview < Views::Base
  def initialize(article:)
    @article = article
  end

  def view_template
    div(class: "max-w-3xl mx-auto px-4 py-8") do
      article(class: "prose prose-lg dark:prose-invert max-w-none") do
        header(class: "mb-8") do
          div(class: "flex items-center gap-2 mb-4") do
            render Components::Admin::StatusBadge.new(status: @article.status)

            @article.categories.each do |category|
              span(class: "text-xs font-medium px-2 py-1 rounded-full bg-secondary text-secondary-foreground") do
                plain category.name
              end
            end
          end

          h1(class: "text-3xl font-bold text-foreground") { plain @article.title }

          p(class: "text-sm text-muted-foreground mt-2") do
            plain @article.created_at.strftime("%B %d, %Y")
          end
        end

        div(class: "article-body") do
          raw safe(MarkdownRenderer.render(@article.body))
        end
      end

      footer(class: "mt-8 pt-4 border-t border-border flex gap-4") do
        a(
          href: helpers.edit_article_path(slug: @article.slug),
          class: "px-4 py-2 text-sm border border-input rounded-lg hover:bg-accent transition-colors",
          data: { turbo_frame: "modal" }
        ) { "Edit" }

        a(
          href: helpers.export_article_path(slug: @article.slug),
          class: "px-4 py-2 text-sm border border-input rounded-lg hover:bg-accent transition-colors"
        ) { "Export Markdown" }
      end
    end

    turbo_frame_tag("modal")
  end
end
```

**Step 5: Update the admin index card links to point to preview**

In `app/views/admin/articles/index.rb`, the `admin_article_card` method links to `article_path`. Update to `preview_article_path`:

```ruby
a(
  href: helpers.preview_article_path(slug: article.slug),
  class: "flex-1"
) do
```

Remove the `turbo_frame: "modal"` and `turbo_action: "advance"` data attributes since preview is a full page, not a modal.

**Step 6: Update any markdown preview references**

Check `app/components/admin/markdown_preview.rb` (or wherever the stimulus controller posts to). The URL for live markdown preview was `POST /articles/preview` and is now `POST /articles/markdown_preview`. Update the Stimulus controller or component that posts to this endpoint.

Search for references to `preview_articles_path` or `/articles/preview` and update to `markdown_preview_articles_path` or `/articles/markdown_preview`.

**Step 7: Run all tests**

Run: `bin/rails test`
Expected: All PASS

**Step 8: Commit**

```bash
git add -A
git commit -m "Add article preview page and rename markdown preview endpoint"
```

---

### Task 5: Add markdown export

**Files:**
- Modify: `app/controllers/articles_controller.rb` (add `export` action)
- Create: `test/controllers/articles_controller_test.rb` (add export tests)

**Step 1: Write the failing test**

Add to `test/controllers/articles_controller_test.rb`:

```ruby
context "GET #export (authenticated)" do
  setup do
    @user = create(:user)
    sign_in(@user)
  end

  should "download the article as markdown" do
    article = create(:article, :published, title: "My Article", body: "## Hello\n\nSome content here.")

    get export_article_url(slug: article.slug)

    assert_response :success
    assert_equal "text/markdown", response.content_type
    assert_match "attachment", response.headers["Content-Disposition"]
    assert_includes response.headers["Content-Disposition"], "#{article.slug}.md"
    assert_includes response.body, "# My Article"
    assert_includes response.body, "## Hello"
    assert_includes response.body, "Some content here."
  end
end

context "GET #export (unauthenticated)" do
  should "redirect to sign in" do
    article = create(:article, :draft)
    get export_article_url(slug: article.slug)
    assert_response :redirect
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bin/rails test test/controllers/articles_controller_test.rb`
Expected: FAIL (no `export` action yet)

**Step 3: Implement the export action**

In `app/controllers/articles_controller.rb`, add:

```ruby
def export
  markdown = "# #{@article.title}\n\n#{@article.body}"
  send_data markdown,
    filename: "#{@article.slug}.md",
    type: "text/markdown",
    disposition: "attachment"
end
```

The route was already added in Task 4 (`get :export` in the member block).

**Step 4: Run tests to verify they pass**

Run: `bin/rails test test/controllers/articles_controller_test.rb`
Expected: All PASS

**Step 5: Commit**

```bash
git add app/controllers/articles_controller.rb test/controllers/articles_controller_test.rb
git commit -m "Add markdown export for articles"
```

---

### Task 6: Update layout — remove public sign in/out toggle

**Files:**
- Modify: `app/views/layouts/application.html.erb:31-37`

**Step 1: Simplify the nav**

Since all pages now require authentication (except login), the "Sign in" link is unnecessary. Replace lines 31-37:

```erb
<nav class="flex items-center gap-4">
  <% if authenticated? %>
    <%= button_to "Sign out", session_path(Current.session), method: :delete, class: "text-sm text-muted-foreground hover:text-foreground cursor-pointer" %>
  <% end %>
</nav>
```

**Step 2: Run all tests**

Run: `bin/rails test`
Expected: All PASS

**Step 3: Commit**

```bash
git add app/views/layouts/application.html.erb
git commit -m "Remove sign-in link from layout since all pages require auth"
```

---

### Task 7: Update system tests

**Files:**
- Modify: `test/system/articles_test.rb`

**Step 1: Rewrite system tests for notebook behavior**

Replace the entire file:

```ruby
require "application_system_test_case"

class ArticlesTest < ApplicationSystemTestCase
  setup do
    @user = create(:user)
    @category = create(:category, name: "Ruby")
    @published = create(:article, :published, title: "Published Article", categories: [@category])
    @draft = create(:article, :draft, title: "Draft Article")
  end

  test "unauthenticated user is redirected to login" do
    visit root_url
    assert_current_path new_session_path
  end

  test "authenticated user sees all articles with admin controls" do
    sign_in_as(@user)
    assert_text "Published Article"
    assert_text "Draft Article"
    assert_text "New Article"
    assert_text "Manage Categories"
  end

  test "authenticated user can filter by category" do
    create(:article, :published, title: "Untagged Article")
    sign_in_as(@user)
    click_on "Ruby"
    assert_text "Published Article"
    assert_no_text "Untagged Article"
  end

  test "authenticated user can preview an article" do
    sign_in_as(@user)
    click_on "Published Article"
    assert_text "Published Article"
    assert_text "Export Markdown"
  end

  private

  def sign_in_as(user)
    visit new_session_url
    fill_in "email_address", with: user.email_address
    fill_in "password", with: "password123"
    click_button "Sign in"
  end
end
```

**Step 2: Run system tests**

Run: `bin/rails test:system`
Expected: All PASS

**Step 3: Commit**

```bash
git add test/system/articles_test.rb
git commit -m "Update system tests for personal notebook behavior"
```

---

### Task 8: Run full CI and fix any issues

**Step 1: Run the full CI suite**

```bash
bin/ci
```

Expected: All checks pass (rubocop, brakeman, bundler-audit, tests, seed test)

**Step 2: Fix any RuboCop or test issues found**

Address any offenses or failures.

**Step 3: Final commit if needed**

```bash
git add -A
git commit -m "Fix CI issues from notebook transformation"
```
