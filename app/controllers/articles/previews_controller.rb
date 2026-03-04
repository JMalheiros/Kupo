module Articles
  class PreviewsController < ApplicationController
    def show
      @article = Article.find_by!(slug: params[:slug])

      render Views::Articles::Preview::Show.new(article: @article)
    end
  end
end
