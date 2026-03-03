class ArticlesController < ApplicationController
  allow_unauthenticated_access only: [ :index, :show ]

  before_action :set_article, only: [ :show ]

  def index
    @articles = Article.published.recent
    @articles = @articles.joins(:categories).where(categories: { slug: params[:category] }) if params[:category].present?
    @categories = Category.all
    render Views::Articles::Index.new(articles: @articles, categories: @categories, current_category: params[:category])
  end

  def show
    render Views::Articles::Show.new(article: @article)
  end

  private

  def set_article
    @article = if authenticated?
      Article.find_by!(slug: params[:slug])
    else
      Article.published.find_by!(slug: params[:slug])
    end
  end
end
