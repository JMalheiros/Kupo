# frozen_string_literal: true

class Components::Admin::Articles::Filters < Components::Base
  def initialize(categories:, current_category: nil, current_status: nil, current_sort: nil)
    @categories = categories
    @current_category = current_category
    @current_status = current_status
    @current_sort = current_sort || "newest"
  end

  def view_template
    # Category filter
    nav(class: "flex flex-wrap gap-2 mb-4") do
      a(
        href: filter_path,
        class: category_filter_class(nil),
        data: { turbo_frame: "articles" }
      ) { "All" }

      @categories.each do |category|
        a(
          href: filter_path(category: category.slug),
          class: category_filter_class(category.slug),
          data: { turbo_frame: "articles" }
        ) { plain category.name }
      end
    end

    # Status filter + sort toggle
    nav(class: "flex items-center justify-between mb-4") do
      div(class: "flex gap-2") do
        %w[all draft scheduled published].each do |status|
          a(
            href: filter_path(status: status == "all" ? nil : status),
            class: status_filter_class(status),
            data: { turbo_frame: "articles" }
          ) { plain status.capitalize }
        end
      end

      div(class: "flex gap-1") do
        %w[newest oldest].each do |sort|
          a(
            href: filter_path(sort: sort),
            class: sort_filter_class(sort),
            data: { turbo_frame: "articles" }
          ) { plain sort.capitalize }
        end
      end
    end
  end

  private

  def filter_path(overrides = {})
    params = {}
    params[:category] = overrides.key?(:category) ? overrides[:category] : @current_category
    params[:status] = overrides.key?(:status) ? overrides[:status] : @current_status
    params[:sort] = overrides.key?(:sort) ? overrides[:sort] : @current_sort
    params.compact!
    params.delete(:sort) if params[:sort] == "newest"
    root_path(**params)
  end

  def category_filter_class(slug)
    base = "px-4 py-2 rounded-full text-sm font-medium transition-colors"
    if @current_category == slug || (@current_category.nil? && slug.nil?)
      "#{base} bg-primary text-primary-foreground"
    else
      "#{base} bg-secondary text-secondary-foreground hover:bg-accent"
    end
  end

  def status_filter_class(status)
    base = "text-sm transition-colors"
    current = @current_status || "all"
    if current == status
      "#{base} text-foreground font-medium"
    else
      "#{base} text-muted-foreground hover:text-foreground"
    end
  end

  def sort_filter_class(sort)
    base = "text-sm transition-colors"
    if @current_sort == sort
      "#{base} text-foreground font-medium"
    else
      "#{base} text-muted-foreground hover:text-foreground"
    end
  end
end
