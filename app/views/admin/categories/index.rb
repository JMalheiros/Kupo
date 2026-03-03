# frozen_string_literal: true

class Views::Admin::Categories::Index < Views::Base
  def initialize(categories:, new_category: nil)
    @categories = categories
    @new_category = new_category || Category.new
  end

  def view_template
    div do
      h1 { "Manage Categories" }
      @categories.each do |category|
        div { plain category.name }
      end
    end
  end
end
