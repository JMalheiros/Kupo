# frozen_string_literal: true

module Articles
  class PlansController < ApplicationController
    def create
      @article = Article.find_by!(slug: params[:slug])
      GeneratePlanJob.perform_later(@article, Current.user)
      redirect_to edit_article_url(slug: @article.slug)
    end
  end
end
