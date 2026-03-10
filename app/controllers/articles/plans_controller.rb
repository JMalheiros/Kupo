# frozen_string_literal: true

module Articles
  class PlansController < ApplicationController
    def create
      @article = Article.find_by!(slug: params[:slug])
      @categories = Category.all

      GeneratePlanJob.perform_later(@article, Current.user)
      render Views::Admin::Articles::Form.new(article: @article, categories: @categories)
    end
  end
end
