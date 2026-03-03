# frozen_string_literal: true

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
