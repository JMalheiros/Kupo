class ArticlesController < ApplicationController
  before_action :set_article, only: [ :edit, :update, :destroy ]

  def index
    @categories = Category.all
    @articles = ArticlesQuery.new(params: params).call

    render Views::Admin::Articles::Index.new(articles: @articles, categories: @categories, current_category: params[:category], current_status: params[:status])
  end

  def new
    @article = Article.new
    @categories = Category.all
    render Views::Admin::Articles::Form.new(article: @article, categories: @categories)
  end

  def create
    @article = Article.new(article_params)

    if @article.save
      redirect_to preview_article_url(slug: @article.slug)
    else
      @categories = Category.all
      render Views::Admin::Articles::Form.new(article: @article, categories: @categories), status: :unprocessable_entity
    end
  end

  def edit
    @categories = Category.all
    render Views::Admin::Articles::Form.new(article: @article, categories: @categories)
  end

  def update
    if @article.update(article_params)
      redirect_to preview_article_url(slug: @article.slug)
    else
      @categories = Category.all
      render Views::Admin::Articles::Form.new(article: @article, categories: @categories), status: :unprocessable_entity
    end
  end

  def destroy
    @article.destroy!
    redirect_to root_url
  end

  private

  def set_article
    @article = Article.find_by!(slug: params[:slug])
  end

  def article_params
    params.require(:article).permit(:title, :body, :slug, category_ids: [])
  end
end
