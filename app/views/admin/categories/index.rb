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
            div(class: "space-y-2") do
              @categories.each do |category|
                div(class: "flex items-center justify-between p-3 rounded-lg border border-border") do
                  span(class: "text-foreground") { plain category.name }
                  Button(
                    variant: :ghost,
                    size: :sm,
                    formaction: helpers.category_path(category),
                    formmethod: "post",
                    name: "_method",
                    value: "delete",
                    class: "text-destructive hover:text-destructive/80",
                    data: { turbo_confirm: "Delete #{category.name}?" }
                  ) { "Delete" }
                end
              end
            end
          end
        end
      end
    end
  end
end
