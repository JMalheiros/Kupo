module Articles
  class PublishesController < ApplicationController
    def create
      @article = Article.find_by!(slug: params[:slug])

      case params[:publish_action]
      when "now"
        @article.publish_now!
      when "schedule"
        @article.schedule!(Time.zone.parse(params[:published_at]))
      end

      redirect_to preview_article_url(slug: @article.slug)
    end
  end
end
