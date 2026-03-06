class ArticlesQuery
  PER_PAGE = 10

  attr_reader :total_count, :total_pages

  def initialize(params:)
    @category = params[:category]
    @status = params[:status]
    @sort = params[:sort]
    @page = [ (params[:page] || 1).to_i, 1 ].max
  end

  def call
    scope = Article.all
    scope = filter_by_category(scope)
    scope = filter_by_status(scope)
    scope = apply_sort(scope)

    @total_count = scope.count
    @total_pages = (@total_count.to_f / PER_PAGE).ceil

    scope.offset((@page - 1) * PER_PAGE).limit(PER_PAGE)
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

  def apply_sort(scope)
    if @sort == "oldest"
      scope.order(published_at: :asc, created_at: :asc)
    else
      scope.order(published_at: :desc, created_at: :desc)
    end
  end
end
