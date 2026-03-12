# frozen_string_literal: true

module Articles
  class PlansController < ApplicationController
    def create
      @article = Article.find_by!(slug: params[:slug])

      GeneratePlanJob.perform_later(@article, Current.user)

      render turbo_stream: turbo_stream.replace(
        "article-plan-editor",
        Components::Admin::Articles::ArticlePlan.new(article: @article, generating: true)
      )
    end
  end
end
