# frozen_string_literal: true

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
            class: "px-4 py-2 text-sm border border-input rounded-lg hover:bg-accent transition-colors",
            data: { turbo_frame: "modal" }
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
          class: "text-sm text-destructive hover:text-destructive/80 cursor-pointer",
          data: { turbo_confirm: "Are you sure you want to delete this article?" }
        ) { "Delete" }
      end
    end
  end
end
