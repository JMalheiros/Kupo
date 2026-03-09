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
        render Components::Admin::Articles::Filters.new(
          categories: @categories,
          current_category: @current_category,
          current_status: @current_status,
          current_sort: @current_sort
        )

        div(class: "space-y-4") do
          @articles.each do |article|
            render Components::Admin::Articles::ArticleCard.new(article: article)
          end
        end

        if @total_pages > 1
          render Components::Admin::Articles::ArticlePagination.new(
            current_page: @current_page,
            total_pages: @total_pages,
            current_category: @current_category,
            current_status: @current_status,
            current_sort: @current_sort
          )
        end
      end
    end

    turbo_frame_tag("modal")
  end
end
