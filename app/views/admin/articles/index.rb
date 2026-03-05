# frozen_string_literal: true

class Views::Admin::Articles::Index < Views::Base
  def initialize(articles:, categories:, current_category: nil, current_status: nil)
    @articles = articles
    @categories = categories
    @current_category = current_category
    @current_status = current_status
  end

  def view_template
    div(class: "max-w-4xl mx-auto px-4 py-8") do
      div(class: "flex items-center justify-between mb-8") do
        Heading(level: 1) { "Articles" }

        div(class: "flex gap-2") do
          Link(
            href: helpers.categories_path,
            variant: :outline,
            size: :sm,
            data: { turbo_frame: "modal" }
          ) { "Manage Categories" }

          Link(
            href: helpers.new_article_path,
            variant: :primary,
            size: :sm,
            data: { turbo_frame: "modal" }
          ) { "New Article" }
        end
      end

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
            class: status_filter_class(status)
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
        href: helpers.preview_article_path(slug: article.slug),
        class: "flex-1",
        data: { turbo_frame: "_top" }
      ) do
        div(class: "flex items-center gap-3") do
          Badge(variant: status_variant(article.status)) { plain article.status.capitalize }
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
        Link(
          href: helpers.edit_article_path(slug: article.slug),
          variant: :ghost,
          size: :sm,
          data: { turbo_frame: "modal" }
        ) { "Edit" }

        Button(
          variant: :ghost,
          size: :sm,
          formaction: helpers.article_path(slug: article.slug),
          formmethod: "post",
          name: "_method",
          value: "delete",
          class: "text-destructive hover:text-destructive/80",
          data: { turbo_confirm: "Are you sure you want to delete this article?" }
        ) { "Delete" }
      end
    end
  end

  def status_variant(status)
    case status
    when "published" then :green
    when "scheduled" then :yellow
    when "draft" then :gray
    end
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
end
