module Articles
  class PublishesController < ApplicationController
    def create
      @article = Article.find_by!(slug: params[:slug])

      case params[:publish_action]
      when "now"
        @article.publish_now!
      when "schedule"
        datetime = "#{params[:published_at]} #{params[:publish_time]}"
        @article.schedule!(Time.zone.parse(datetime))
      end

      redirect_to articles_url
    end
  end
end
