module Articles
  class ExportsController < ApplicationController
    def create
      @article = Article.find_by!(slug: params[:slug])

      markdown = "# #{@article.title}\n\n#{@article.body}"
      send_data markdown,
        filename: "#{@article.slug}.md",
        type: "text/markdown",
        disposition: "attachment"
    end
  end
end
