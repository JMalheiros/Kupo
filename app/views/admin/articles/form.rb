# frozen_string_literal: true

class Views::Admin::Articles::Form < Views::Base
  def initialize(article:, categories:)
    @article = article
    @categories = categories
  end

  def view_template
    turbo_frame_tag("modal") do
      render Components::Modal.new do
        form_content
      end
    end
  end

  private

  def form_content
    h1(class: "text-2xl font-bold text-foreground mb-6") do
      plain @article.new_record? ? "New Article" : "Edit Article"
    end

    url = @article.new_record? ? helpers.articles_path : helpers.article_path(slug: @article.slug)
    method = @article.new_record? ? "post" : "patch"

    form_with_tag(url: url, method: method) do
      # Title
      div(class: "mb-4") do
        label(for: "article_title", class: "block text-sm font-medium text-foreground mb-1") { "Title" }
        input(
          type: "text",
          name: "article[title]",
          id: "article_title",
          value: @article.title,
          class: "w-full px-4 py-2 border border-input rounded-lg bg-background text-foreground focus:outline-none focus:ring-2 focus:ring-ring",
          required: true
        )
        render_errors_for(:title)
      end

      # Categories
      div(class: "mb-4") do
        label(class: "block text-sm font-medium text-foreground mb-1") { "Categories" }
        div(class: "flex flex-wrap gap-2") do
          @categories.each do |category|
            label(class: "inline-flex items-center gap-1 cursor-pointer") do
              input(
                type: "checkbox",
                name: "article[category_ids][]",
                value: category.id,
                checked: @article.category_ids.include?(category.id),
                class: "rounded border-input"
              )
              span(class: "text-sm text-foreground") { plain category.name }
            end
          end
          # Hidden field to allow empty category_ids
          input(type: "hidden", name: "article[category_ids][]", value: "")
        end
      end

      # Markdown editor with preview
      div(class: "mb-4") do
        render Components::Admin::MarkdownPreview.new(body: @article.body)
      end

      # Image upload
      div(class: "mb-6", data: { controller: "image-upload" }) do
        label(class: "block text-sm font-medium text-foreground mb-1") { "Upload Image" }
        input(
          type: "file",
          accept: "image/*",
          class: "text-sm text-muted-foreground",
          data: { image_upload_target: "input", action: "change->image-upload#upload" }
        )
      end

      # Submit
      div(class: "flex justify-end gap-4") do
        button(
          type: "submit",
          class: "px-6 py-2 bg-primary text-primary-foreground rounded-lg hover:bg-primary/90 transition-colors cursor-pointer"
        ) { plain @article.new_record? ? "Create Article" : "Update Article" }
      end
    end
  end

  def form_with_tag(url:, method:, &block)
    actual_method = method == "patch" ? "post" : method
    form(action: url, method: actual_method, class: "space-y-4") do
      input(type: "hidden", name: "authenticity_token", value: helpers.form_authenticity_token)
      input(type: "hidden", name: "_method", value: method) if method == "patch"
      yield
    end
  end

  def render_errors_for(field)
    return unless @article.errors[field].any?
    @article.errors[field].each do |error|
      p(class: "text-sm text-destructive mt-1") { plain error }
    end
  end
end
