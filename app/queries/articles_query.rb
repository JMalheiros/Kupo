class ArticlesQuery
  def initialize(params:, authenticated: false)
    @category = params[:category]
    @status = params[:status]
    @authenticated = authenticated
  end

  def call
    scope = base_scope
    scope = filter_by_category(scope)
    scope = filter_by_status(scope)
    scope
  end

  private

  def base_scope
    if @authenticated
      Article.recent
    else
      Article.published.recent
    end
  end

  def filter_by_category(scope)
    return scope unless @category.present?

    scope.joins(:categories).where(categories: { slug: @category })
  end

  def filter_by_status(scope)
    return scope unless @authenticated && @status.present?

    scope.where(status: @status)
  end
end
