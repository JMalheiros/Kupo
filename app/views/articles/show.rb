# frozen_string_literal: true

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
