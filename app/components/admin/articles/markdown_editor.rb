# frozen_string_literal: true

class Components::Admin::Articles::MarkdownEditor < Components::Base
  def initialize(article:)
    @article = article
  end

  def view_template
    div(class: "col-span-3 mt-4") do
      render Components::Admin::Articles::MarkdownPreview.new(body: @article.body)
    end
  end
end
