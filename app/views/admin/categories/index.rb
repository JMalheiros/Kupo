# frozen_string_literal: true

class Views::Admin::Categories::Index < Views::Base
  def initialize(categories:, new_category: nil)
    @categories = categories
    @new_category = new_category || Category.new
  end

  def view_template
    turbo_frame_tag("modal") do
      Dialog(open: true) do
        DialogContent(size: :sm) do
          DialogHeader do
            DialogTitle { "Manage Categories" }
          end

          DialogMiddle do
            # New category form
            form(action: helpers.categories_path, method: "post", class: "flex gap-2 mb-6") do
              input(type: "hidden", name: "authenticity_token", value: helpers.form_authenticity_token)
              Input(
                type: :text,
                name: "category[name]",
                value: @new_category.name,
                placeholder: "New category name",
                required: true,
                class: "flex-1"
              )
              Button(type: :submit, size: :sm) { "Add" }
            end

            # Category list
            div(id: "categories-list", class: "space-y-2") do
              @categories.each do |category|
                render_category_row(category)
              end
            end
          end
        end
      end
    end
  end

  private

  def render_category_row(category)
    div(id: "category_#{category.id}", class: "flex items-center justify-between p-3 rounded-lg border border-border") do
      span(class: "text-foreground") { plain category.name }
      form(action: helpers.category_path(category), method: "post") do
        input(type: "hidden", name: "authenticity_token", value: helpers.form_authenticity_token)
        input(type: "hidden", name: "_method", value: "delete")
        Button(
          type: :submit,
          variant: :ghost,
          size: :sm,
          class: "text-destructive hover:text-destructive/80",
          data: { turbo_confirm: "Delete #{category.name}?" }
        ) { "Delete" }
      end
    end
  end
end
