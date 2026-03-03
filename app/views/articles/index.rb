# frozen_string_literal: true

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
