# frozen_string_literal: true

class Views::Categories::Filter < Views::Base
  def initialize(categories:, current_category: nil)
    @categories = categories
    @current_category = current_category
  end

  def view_template
    nav(class: "flex flex-wrap gap-2 mb-8") do
      a(
        href: helpers.root_path,
        class: filter_class(nil),
        data: { turbo_frame: "articles" }
      ) { "All" }

      @categories.each do |category|
        a(
          href: helpers.root_path(category: category.slug),
          class: filter_class(category.slug),
          data: { turbo_frame: "articles" }
        ) { plain category.name }
      end
    end
  end

  private

  def filter_class(slug)
    base = "px-4 py-2 rounded-full text-sm font-medium transition-colors"
    if @current_category == slug || (@current_category.nil? && slug.nil?)
      "#{base} bg-primary text-primary-foreground"
    else
      "#{base} bg-secondary text-secondary-foreground hover:bg-accent"
    end
  end
end
