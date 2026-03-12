# frozen_string_literal: true

class Components::Admin::Articles::ArticleFields < Components::Base
  def initialize(article:, categories:)
    @article = article
    @categories = categories
  end

  def view_template
    # Title
    FormField(class: "col-span-3 mb-4") do
      FormFieldLabel(for: "article_title") { "Title" }
      Input(
        type: :text,
        name: "article[title]",
        id: "article_title",
        value: @article.title,
        required: true
      )
      render_errors_for(:title)
    end

    # Categories (Combobox multi-select)
    div(class: "col-span-1 mb-4") do
      FormField do
        FormFieldLabel { "Categories" }
        Combobox(create_url: categories_path, create_param: "category[name]") do
          ComboboxTrigger(placeholder: "Select categories")

          ComboboxPopover do
            ComboboxSearchInput(
              placeholder: "Search or create categories...",
              data: { action: "keydown->ruby-ui--combobox#onSearchKeydown" }
            )

            ComboboxList(id: "category-combobox-list") do
              ComboboxEmptyState do
                plain "No categories found. Press Enter to create."
              end

              @categories.each do |category|
                ComboboxItem do
                  ComboboxCheckbox(
                    name: "article[category_ids][]",
                    value: category.id,
                    checked: @article.category_ids.include?(category.id)
                  )
                  span { plain category.name }
                end
              end
            end
          end
        end
        # Hidden field to allow empty category_ids
        Input(type: :hidden, name: "article[category_ids][]", value: "")
      end
    end

    # Image upload
    div(class: "col-span-1", data: { controller: "image-upload" }) do
      FormField do
        FormFieldLabel { "Upload Image" }
        Input(
          type: :file,
          accept: "image/*",
          data: { image_upload_target: "input", action: "change->image-upload#upload" }
        )
      end
    end
  end

  private

  def render_errors_for(field)
    return unless @article.errors[field].any?
    @article.errors[field].each do |error|
      FormFieldError { plain error }
    end
  end
end
