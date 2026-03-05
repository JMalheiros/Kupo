# frozen_string_literal: true

class Components::Admin::MarkdownPreview < Components::Base
  def initialize(body: "")
    @body = body
  end

  def view_template
    div(
      class: "grid grid-cols-2 gap-4 h-[60vh]",
      data: { controller: "markdown-preview" }
    ) do
      # Editor pane
      div(class: "flex flex-col") do
        FormFieldLabel(class: "mb-2") { "Markdown" }
        textarea(
          name: "article[body]",
          class: "flex-1 w-full p-4 font-mono text-sm border border-input rounded-lg bg-background text-foreground resize-none focus:outline-none focus:ring-2 focus:ring-ring",
          data: { markdown_preview_target: "input", action: "input->markdown-preview#update" },
          placeholder: "Write your article in markdown..."
        ) { plain @body }
      end

      # Preview pane
      div(class: "flex flex-col") do
        FormFieldLabel(class: "mb-2") { "Preview" }
        div(
          class: "flex-1 overflow-y-auto p-4 border border-input rounded-lg bg-background prose prose-sm dark:prose-invert max-w-none",
          data: { markdown_preview_target: "preview" }
        ) do
          raw safe(MarkdownRenderer.render(@body)) if @body.present?
        end
      end
    end
  end
end
