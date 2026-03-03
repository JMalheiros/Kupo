# frozen_string_literal: true

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
