class ArticlesQuery
  def initialize(params:)
    @category = params[:category]
    @status = params[:status]
  end

  def call
    scope = Article.recent
    scope = filter_by_category(scope)
    scope = filter_by_status(scope)
    scope
  end

  private

  def filter_by_category(scope)
    return scope unless @category.present?

    scope.joins(:categories).where(categories: { slug: @category })
  end

  def filter_by_status(scope)
    return scope unless @status.present?

    scope.where(status: @status)
  end
end
