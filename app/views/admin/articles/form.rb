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
            if @article.persisted?
              tabbed_content
            else
              article_form
            end
          end
        end
      end
    end
  end

  private

  def tabbed_content
    div do
      Tabs(default: "edit") do
        TabsList do
          TabsTrigger(value: "plan") { "Plan" }
          TabsTrigger(value: "edit") { "Edit" }
          TabsTrigger(value: "review") { "Review" }
        end

        # Edit and Plan tabs are inside the same form
        article_form_with_plan

        # Review tab is outside the form (has its own forms)
        TabsContent(class: "col-span-3 rounded-lg border border-border bg-muted/50 p-4", value: "review") do
          render Components::Admin::Reviews.new(article: @article)
        end
      end
    end
  end

  def article_form
    url = @article.new_record? ? articles_path : article_path(slug: @article.slug)
    method = @article.new_record? ? "post" : "patch"

    form_with_tag(url: url, method: method) do
      article_fields
      submit_button
      markdown_editor
    end
  end

  def article_form_with_plan
    url = article_path(slug: @article.slug)

    form_with_tag(url: url, method: "patch") do
      TabsContent(class: "col-span-3 rounded-lg border border-border bg-muted/50 p-4", value: "edit") do
        article_fields
        submit_button
        markdown_editor
      end

      TabsContent(class: "col-span-3 rounded-lg border border-border bg-muted/50 p-4", value: "plan") do
        render Components::Admin::Articles::ArticlePlan.new(article: @article)
        div(class: "col-span-3 flex justify-end gap-4 mt-4") do
          Button(type: :submit) { "Save Plan" }
        end
      end
    end
  end

  def article_fields
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
  end

  def submit_button
    div(class: "col-span-3 flex justify-end gap-4") do
      Button(type: :submit) { plain @article.new_record? ? "Create Article" : "Update Article" }
    end
  end

  def markdown_editor
    div(class: "col-span-3 my-4") do
      render Components::Admin::Articles::MarkdownPreview.new(body: @article.body)
    end
  end

  def form_with_tag(url:, method:, &block)
    actual_method = method == "patch" ? "post" : method
    form(action: url, method: actual_method, class: "grid grid-cols-3 space-y-4 gap-3") do
      input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)
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
