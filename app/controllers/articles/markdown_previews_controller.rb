module Articles
  class MarkdownPreviewsController < ApplicationController
    def show
      html = MarkdownRenderer.render(params[:body])
      render html: html.html_safe, layout: false
    end
  end
end
