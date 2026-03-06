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

      turbo_frame_tag("articles") do
        render Views::Admin::Articles::Filters.new(
          categories: @categories,
          current_category: @current_category,
          current_status: @current_status
        )

        div(class: "space-y-4") do
          @articles.each do |article|
            render Views::Admin::Articles::ArticleCard.new(article: article)
          end
        end
      end
    end

    turbo_frame_tag("modal")
  end
end
