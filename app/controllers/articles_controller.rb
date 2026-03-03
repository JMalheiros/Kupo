class ArticlesController < ApplicationController
  allow_unauthenticated_access only: [ :index, :show ]

  before_action :set_article, only: [ :show, :edit, :update, :destroy, :publish ]

  def index
    @articles = Article.published.recent
    @articles = @articles.joins(:categories).where(categories: { slug: params[:category] }) if params[:category].present?
    @categories = Category.all
    render Views::Articles::Index.new(articles: @articles, categories: @categories, current_category: params[:category])
  end

  def show
    modal = turbo_frame_request_id == "modal"
    render Views::Articles::Show.new(article: @article, modal: modal)
  end

  def new
    @article = Article.new
    @categories = Category.all
    render Views::Admin::Articles::Form.new(article: @article, categories: @categories)
  end

  def create
    @article = Article.new(article_params)

    if @article.save
      redirect_to article_url(slug: @article.slug)
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
      redirect_to article_url(slug: @article.slug)
    else
      @categories = Category.all
      render Views::Admin::Articles::Form.new(article: @article, categories: @categories), status: :unprocessable_entity
    end
  end

  def destroy
    @article.destroy!
    redirect_to root_url
  end

  def publish
    case params[:publish_action]
    when "now"
      @article.publish_now!
    when "schedule"
      @article.schedule!(Time.zone.parse(params[:published_at]))
    end

    redirect_to article_url(slug: @article.slug)
  end

  def preview
    html = MarkdownRenderer.render(params[:body])
    render html: html.html_safe, layout: false
  end

  private

  def set_article
    @article = if authenticated?
      Article.find_by!(slug: params[:slug])
    else
      Article.published.find_by!(slug: params[:slug])
    end
  end

  def article_params
    params.require(:article).permit(:title, :body, :slug, category_ids: [])
  end
end
