# frozen_string_literal: true

class Views::Admin::Articles::Form < Views::Base
  def initialize(article:, categories:)
    @article = article
    @categories = categories
  end

  def view_template
    turbo_frame_tag("modal") do
      Dialog(open: true) do
        DialogContent(size: :xxl) do
          DialogHeader do
            DialogTitle { plain @article.new_record? ? "New Article" : "Edit Article" }
          end

          DialogMiddle(class: "py-0") do
            form_content
          end
        end
      end
    end
  end

  private

  def form_content
    url = @article.new_record? ? helpers.articles_path : helpers.article_path(slug: @article.slug)
    method = @article.new_record? ? "post" : "patch"

    form_with_tag(url: url, method: method) do
      # Title
      FormField(class: "col-span-2 mb-4") do
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
          Combobox(create_url: helpers.categories_path, create_param: "category[name]") do
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
          input(type: "hidden", name: "article[category_ids][]", value: "")
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

      # Submit
      div(class: "col-span-2 flex justify-end gap-4") do
        Button(type: :submit) { plain @article.new_record? ? "Create Article" : "Update Article" }
      end

      # Markdown editor with preview
      div(class: "col-span-2 my-4") do
        render Components::Admin::MarkdownPreview.new(body: @article.body)
      end
    end
  end

  def form_with_tag(url:, method:, &block)
    actual_method = method == "patch" ? "post" : method
    form(action: url, method: actual_method, class: "grid grid-cols-2 space-y-4 gap-3") do
      input(type: "hidden", name: "authenticity_token", value: helpers.form_authenticity_token)
      input(type: "hidden", name: "_method", value: method) if method == "patch"
      yield
    end
  end

  def render_errors_for(field)
    return unless @article.errors[field].any?
    @article.errors[field].each do |error|
      FormFieldError { plain error }
    end
  end
end
