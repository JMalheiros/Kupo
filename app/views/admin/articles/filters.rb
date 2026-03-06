# frozen_string_literal: true

class Views::Admin::Articles::Filters < Views::Base
  def initialize(categories:, current_category: nil, current_status: nil)
    @categories = categories
    @current_category = current_category
    @current_status = current_status
  end

  def view_template
    # Category filter
    nav(class: "flex flex-wrap gap-2 mb-4") do
      status_params = @current_status ? { status: @current_status } : {}
      a(
        href: root_path(**status_params),
        class: category_filter_class(nil),
        data: { turbo_frame: "articles" }
      ) { "All" }

      @categories.each do |category|
        a(
          href: root_path(category: category.slug, **status_params),
          class: category_filter_class(category.slug),
          data: { turbo_frame: "articles" }
        ) { plain category.name }
      end
    end

    # Status filter
    nav(class: "flex gap-2 mb-4") do
      %w[all draft scheduled published].each do |status|
        params_hash = status == "all" ? {} : { status: status }
        params_hash[:category] = @current_category if @current_category
        a(
          href: root_path(**params_hash),
          class: status_filter_class(status),
          data: { turbo_frame: "articles" }
        ) { plain status.capitalize }
      end
    end
  end

  private

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
end
