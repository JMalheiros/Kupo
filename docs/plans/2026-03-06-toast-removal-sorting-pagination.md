# Toast Removal + Sorting & Pagination Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Remove the toast notification infrastructure and add sort-by-published_at + pagination (10 per page) to the articles index using RubyUI Pagination components.

**Architecture:** Remove all toast-related files, helpers, and references. Extend `ArticlesQuery` with `sort` (newest/oldest) and `page` params using `offset`/`limit`. Add sort toggle to filters UI and RubyUI `Pagination` to the index view. All filter/sort/page links target the `articles` Turbo Frame.

**Tech Stack:** Rails 8.1, Phlex, RubyUI (Pagination components), Turbo Frames, SQLite3

---

### Task 1: Remove Toast Infrastructure

**Files:**
- Delete: `app/helpers/toast_helper.rb`
- Delete: `app/views/shared/_toast.html.erb`
- Delete: `app/javascript/controllers/toast_controller.js`
- Modify: `app/views/layouts/application.html.erb`
- Modify: `app/jobs/publish_article_job.rb`
- Modify: `app/controllers/articles/publishes_controller.rb`

**Step 1: Delete toast files**

```bash
rm app/helpers/toast_helper.rb
rm app/views/shared/_toast.html.erb
rm app/javascript/controllers/toast_controller.js
```

**Step 2: Remove toast rendering, notifications div, and turbo_stream_from from layout**

In `app/views/layouts/application.html.erb`, replace lines 47-57:

```erb
      <% if authenticated? %>
        <%= turbo_stream_from Current.user %>
      <% end %>

      <div id="notifications" class="fixed bottom-4 right-4 z-50 flex flex-col-reverse gap-2 w-80">
        <% if flash[:toast].present? %>
          <%= render partial: "shared/toast", locals: { variant: flash[:toast]["variant"]&.to_sym, message: flash[:toast]["message"] } %>
        <% end %>
      </div>
```

With just:

```erb
```

(Remove the entire block — no replacement needed.)

**Step 3: Remove broadcast_toast from PublishArticleJob**

In `app/jobs/publish_article_job.rb`, remove all `broadcast_toast` calls and the private method. The job becomes:

```ruby
# frozen_string_literal: true

class PublishArticleJob < ApplicationJob
  queue_as :default

  def perform(article, user = nil)
    case article.status
    when "scheduled"
      article.update!(status: "publishing", published_at: Time.current)
      HugoPublisher.new(article).call
      article.update!(status: "published")
    when "publishing"
      HugoPublisher.new(article).call
      article.update!(status: "published")
    end
  rescue => e
    Rails.logger.error("Hugo publish failed for #{article.slug}: #{e.class} - #{e.message}")
    article.update!(status: "draft")
  end
end
```

**Step 4: Remove flash[:toast] from PublishesController**

In `app/controllers/articles/publishes_controller.rb`, remove line 17:

```ruby
      flash[:toast] = { variant: "success", message: message }
```

The controller keeps the redirect.

**Step 5: Run tests**

```bash
bundle exec rails test
```

Expected: All 83 tests pass (toast was never directly tested).

**Step 6: Commit**

```bash
git add -A
git commit -m "Remove toast notification infrastructure"
```

---

### Task 2: Add Sort and Pagination to ArticlesQuery

**Files:**
- Modify: `app/queries/articles_query.rb`
- Modify: `test/queries/articles_query_test.rb`

**Step 1: Write failing tests for sort and pagination**

Add these tests to `test/queries/articles_query_test.rb`:

```ruby
  # Sort tests
  should "sort by newest (default)" do
    old = create(:article, :published, published_at: 2.days.ago)
    recent = create(:article, :published, published_at: 1.hour.ago)

    result = ArticlesQuery.new(params: {}).call
    published = result.select { |a| a.status == "published" }
    assert published.index(recent) < published.index(old)
  end

  should "sort by oldest when sort param is oldest" do
    old = create(:article, :published, published_at: 2.days.ago)
    recent = create(:article, :published, published_at: 1.hour.ago)

    result = ArticlesQuery.new(params: { sort: "oldest" }).call
    published = result.select { |a| a.status == "published" }
    assert published.index(old) < published.index(recent)
  end

  # Pagination tests
  should "return first page of results with default page size" do
    create_list(:article, 12, :published)

    result = ArticlesQuery.new(params: {}).call
    assert_equal 10, result.size
  end

  should "return second page of results" do
    create_list(:article, 12, :published)

    result = ArticlesQuery.new(params: { page: "2" }).call
    assert_equal 2, result.size
  end

  should "return total count for pagination" do
    create_list(:article, 12, :published)

    query = ArticlesQuery.new(params: {})
    query.call
    assert_equal 12, query.total_count
  end

  should "return total pages" do
    create_list(:article, 22, :published)

    query = ArticlesQuery.new(params: {})
    query.call
    assert_equal 3, query.total_pages
  end
```

**Step 2: Run tests to verify they fail**

```bash
bundle exec rails test test/queries/articles_query_test.rb
```

Expected: New tests FAIL.

**Step 3: Implement sort and pagination in ArticlesQuery**

Replace `app/queries/articles_query.rb`:

```ruby
class ArticlesQuery
  PER_PAGE = 10

  attr_reader :total_count, :total_pages

  def initialize(params:)
    @category = params[:category]
    @status = params[:status]
    @sort = params[:sort]
    @page = [(params[:page] || 1).to_i, 1].max
  end

  def call
    scope = Article.all
    scope = filter_by_category(scope)
    scope = filter_by_status(scope)
    scope = apply_sort(scope)

    @total_count = scope.count
    @total_pages = (@total_count.to_f / PER_PAGE).ceil

    scope.offset((@page - 1) * PER_PAGE).limit(PER_PAGE)
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

  def apply_sort(scope)
    if @sort == "oldest"
      scope.order(published_at: :asc, created_at: :asc)
    else
      scope.order(published_at: :desc, created_at: :desc)
    end
  end
end
```

**Step 4: Update existing tests that assume no pagination**

The existing test "return all articles ordered by most recent" creates 3 articles — still under 10, so it passes. The test "filter by category and status combined" uses `assert_equal [draft_in_category], result.to_a` — still works.

**Step 5: Run tests**

```bash
bundle exec rails test test/queries/articles_query_test.rb
```

Expected: All tests PASS.

**Step 6: Commit**

```bash
git add app/queries/articles_query.rb test/queries/articles_query_test.rb
git commit -m "Add sort and pagination to ArticlesQuery"
```

---

### Task 3: Update Controller and Views for Sort/Pagination

**Files:**
- Modify: `app/controllers/articles_controller.rb`
- Modify: `app/views/admin/articles/index.rb`
- Modify: `app/views/admin/articles/filters.rb`

**Step 1: Update ArticlesController#index to pass new data**

In `app/controllers/articles_controller.rb`, change `index`:

```ruby
  def index
    @categories = Category.all
    @query = ArticlesQuery.new(params: params)
    @articles = @query.call

    render Views::Admin::Articles::Index.new(
      articles: @articles,
      categories: @categories,
      current_category: params[:category],
      current_status: params[:status],
      current_sort: params[:sort],
      current_page: (params[:page] || 1).to_i,
      total_pages: @query.total_pages
    )
  end
```

**Step 2: Update Filters view with sort toggle**

In `app/views/admin/articles/filters.rb`, add `current_sort` to initialize and add a sort toggle:

```ruby
# frozen_string_literal: true

class Views::Admin::Articles::Filters < Views::Base
  def initialize(categories:, current_category: nil, current_status: nil, current_sort: nil)
    @categories = categories
    @current_category = current_category
    @current_status = current_status
    @current_sort = current_sort || "newest"
  end

  def view_template
    # Category filter
    nav(class: "flex flex-wrap gap-2 mb-4") do
      a(
        href: filter_path,
        class: category_filter_class(nil),
        data: { turbo_frame: "articles" }
      ) { "All" }

      @categories.each do |category|
        a(
          href: filter_path(category: category.slug),
          class: category_filter_class(category.slug),
          data: { turbo_frame: "articles" }
        ) { plain category.name }
      end
    end

    # Status filter + sort toggle
    nav(class: "flex items-center justify-between mb-4") do
      div(class: "flex gap-2") do
        %w[all draft scheduled published].each do |status|
          a(
            href: filter_path(status: status == "all" ? nil : status),
            class: status_filter_class(status),
            data: { turbo_frame: "articles" }
          ) { plain status.capitalize }
        end
      end

      div(class: "flex gap-1") do
        %w[newest oldest].each do |sort|
          a(
            href: filter_path(sort: sort),
            class: sort_filter_class(sort),
            data: { turbo_frame: "articles" }
          ) { plain sort.capitalize }
        end
      end
    end
  end

  private

  def filter_path(overrides = {})
    params = {}
    params[:category] = overrides.key?(:category) ? overrides[:category] : @current_category
    params[:status] = overrides.key?(:status) ? overrides[:status] : @current_status
    params[:sort] = overrides.key?(:sort) ? overrides[:sort] : @current_sort
    params.compact!
    params.delete(:sort) if params[:sort] == "newest"
    root_path(**params)
  end

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

  def sort_filter_class(sort)
    base = "text-sm transition-colors"
    if @current_sort == sort
      "#{base} text-foreground font-medium"
    else
      "#{base} text-muted-foreground hover:text-foreground"
    end
  end
end
```

**Step 3: Update Index view with pagination and new params**

Replace `app/views/admin/articles/index.rb`:

```ruby
# frozen_string_literal: true

class Views::Admin::Articles::Index < Views::Base
  def initialize(articles:, categories:, current_category: nil, current_status: nil, current_sort: nil, current_page: 1, total_pages: 1)
    @articles = articles
    @categories = categories
    @current_category = current_category
    @current_status = current_status
    @current_sort = current_sort
    @current_page = current_page
    @total_pages = total_pages
  end

  def view_template
    div(class: "max-w-4xl mx-auto px-4 py-8") do
      div(class: "flex items-center justify-between mb-8") do
        Heading(level: 1) { "Articles" }

        div(class: "flex gap-2") do
          Link(
            href: categories_path,
            variant: :outline,
            size: :sm,
            data: { turbo_frame: "modal" }
          ) { "Manage Categories" }

          Link(
            href: new_article_path,
            variant: :primary,
            size: :sm,
            data: { turbo_frame: "modal" }
          ) { "New Article" }
        end
      end

      turbo_frame_tag("articles") do
        render Views::Admin::Articles::Filters.new(
          categories: @categories,
          current_category: @current_category,
          current_status: @current_status,
          current_sort: @current_sort
        )

        div(class: "space-y-4") do
          @articles.each do |article|
            render Views::Admin::Articles::ArticleCard.new(article: article)
          end
        end

        render_pagination if @total_pages > 1
      end
    end

    turbo_frame_tag("modal")
  end

  private

  def render_pagination
    Pagination(class: "mt-8") do
      PaginationContent do
        if @current_page > 1
          PaginationItem(href: page_path(1), data: { turbo_frame: "articles" }) do
            chevrons_left_icon
            plain "First"
          end
          PaginationItem(href: page_path(@current_page - 1), data: { turbo_frame: "articles" }) do
            chevron_left_icon
            plain "Prev"
          end
        end

        pagination_window.each do |page|
          if page == :ellipsis
            PaginationEllipsis()
          else
            PaginationItem(href: page_path(page), active: page == @current_page, data: { turbo_frame: "articles" }) do
              plain page.to_s
            end
          end
        end

        if @current_page < @total_pages
          PaginationItem(href: page_path(@current_page + 1), data: { turbo_frame: "articles" }) do
            plain "Next"
            chevron_right_icon
          end
          PaginationItem(href: page_path(@total_pages), data: { turbo_frame: "articles" }) do
            plain "Last"
            chevrons_right_icon
          end
        end
      end
    end
  end

  def pagination_window
    window = []
    if @total_pages <= 7
      window = (1..@total_pages).to_a
    else
      window << 1
      if @current_page > 3
        window << :ellipsis
      end
      range_start = [@current_page - 1, 2].max
      range_end = [@current_page + 1, @total_pages - 1].min
      window.concat((range_start..range_end).to_a)
      if @current_page < @total_pages - 2
        window << :ellipsis
      end
      window << @total_pages
      window.uniq
    end
  end

  def page_path(page)
    params = {}
    params[:category] = @current_category if @current_category
    params[:status] = @current_status if @current_status
    params[:sort] = @current_sort if @current_sort.present? && @current_sort != "newest"
    params[:page] = page if page > 1
    root_path(**params)
  end

  def chevrons_left_icon
    svg(xmlns: "http://www.w3.org/2000/svg", width: "24", height: "24", viewbox: "0 0 24 24", stroke_width: "1.5", stroke: "currentColor", fill: "none", stroke_linecap: "round", stroke_linejoin: "round", class: "h-4 w-4") do |s|
      s.path(stroke: "none", d: "M0 0h24v24H0z", fill: "none")
      s.path(d: "M11 7l-5 5l5 5")
      s.path(d: "M17 7l-5 5l5 5")
    end
  end

  def chevron_left_icon
    svg(xmlns: "http://www.w3.org/2000/svg", width: "24", height: "24", viewbox: "0 0 24 24", stroke_width: "1.5", stroke: "currentColor", fill: "none", stroke_linecap: "round", stroke_linejoin: "round", class: "h-4 w-4") do |s|
      s.path(stroke: "none", d: "M0 0h24v24H0z", fill: "none")
      s.path(d: "M15 6l-6 6l6 6")
    end
  end

  def chevrons_right_icon
    svg(xmlns: "http://www.w3.org/2000/svg", width: "24", height: "24", viewbox: "0 0 24 24", stroke_width: "1.5", stroke: "currentColor", fill: "none", stroke_linecap: "round", stroke_linejoin: "round", class: "h-4 w-4") do |s|
      s.path(stroke: "none", d: "M0 0h24v24H0z", fill: "none")
      s.path(d: "M7 7l5 5l-5 5")
      s.path(d: "M13 7l5 5l-5 5")
    end
  end

  def chevron_right_icon
    svg(xmlns: "http://www.w3.org/2000/svg", width: "24", height: "24", viewbox: "0 0 24 24", stroke_width: "1.5", stroke: "currentColor", fill: "none", stroke_linecap: "round", stroke_linejoin: "round", class: "h-4 w-4") do |s|
      s.path(stroke: "none", d: "M0 0h24v24H0z", fill: "none")
      s.path(d: "M9 6l6 6l-6 6")
    end
  end
end
```

**Step 4: Run all tests**

```bash
bundle exec rails test
```

Expected: All tests PASS.

**Step 5: Commit**

```bash
git add app/controllers/articles_controller.rb app/views/admin/articles/index.rb app/views/admin/articles/filters.rb
git commit -m "Add sort toggle and pagination to articles index"
```

---

### Task 4: Add Controller Integration Tests for Sort/Pagination

**Files:**
- Modify: `test/controllers/articles_controller_test.rb`

**Step 1: Write integration tests**

Add to the `"GET #index (authenticated)"` context in `test/controllers/articles_controller_test.rb`:

```ruby
    should "paginate articles showing 10 per page" do
      create_list(:article, 12, :published)

      get root_url
      assert_response :success
    end

    should "show second page of articles" do
      create_list(:article, 12, :published)

      get root_url, params: { page: 2 }
      assert_response :success
    end

    should "sort articles by oldest" do
      create_list(:article, 3, :published)

      get root_url, params: { sort: "oldest" }
      assert_response :success
    end

    should "combine filter, sort, and pagination" do
      category = create(:category, name: "Elixir")
      create_list(:article, 3, :published, categories: [category])

      get root_url, params: { category: category.slug, sort: "oldest", page: 1 }
      assert_response :success
    end
```

**Step 2: Run tests**

```bash
bundle exec rails test test/controllers/articles_controller_test.rb
```

Expected: All PASS.

**Step 3: Run full suite + linting**

```bash
bundle exec rails test && bundle exec rubocop && bundle exec brakeman --no-pager --quiet
```

Expected: All green.

**Step 4: Commit**

```bash
git add test/controllers/articles_controller_test.rb
git commit -m "Add integration tests for sort and pagination"
```
