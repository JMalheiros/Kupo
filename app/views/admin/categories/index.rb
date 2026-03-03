# frozen_string_literal: true

class Views::Admin::Categories::Index < Views::Base
  def initialize(categories:, new_category: nil)
    @categories = categories
    @new_category = new_category || Category.new
  end

  def view_template
    turbo_frame_tag("modal") do
      render Components::Modal.new do
        h1(class: "text-2xl font-bold text-foreground mb-6") { "Manage Categories" }

        # New category form
        form(action: helpers.categories_path, method: "post", class: "flex gap-2 mb-6") do
          input(type: "hidden", name: "authenticity_token", value: helpers.form_authenticity_token)
          input(
            type: "text",
            name: "category[name]",
            value: @new_category.name,
            placeholder: "New category name",
            class: "flex-1 px-4 py-2 border border-input rounded-lg bg-background text-foreground focus:outline-none focus:ring-2 focus:ring-ring",
            required: true
          )
          button(
            type: "submit",
            class: "px-4 py-2 bg-primary text-primary-foreground rounded-lg hover:bg-primary/90 transition-colors cursor-pointer"
          ) { "Add" }
        end

        # Category list
        div(class: "space-y-2") do
          @categories.each do |category|
            div(class: "flex items-center justify-between p-3 rounded-lg border border-border") do
              span(class: "text-foreground") { plain category.name }
              button(
                formaction: helpers.category_path(category),
                formmethod: "post",
                name: "_method",
                value: "delete",
                class: "text-sm text-destructive hover:text-destructive/80 cursor-pointer",
                data: { turbo_confirm: "Delete #{category.name}?" }
              ) { "Delete" }
            end
          end
        end
      end
    end
  end
end
