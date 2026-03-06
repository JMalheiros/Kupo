# frozen_string_literal: true

class Components::Admin::MarkdownPreview < Components::Base
  def initialize(body: "")
    @body = body
  end

  def view_template
    div(data: { controller: "markdown-preview" }) do
      Tabs(default: "write") do
        TabsList do
          TabsTrigger(value: "write") { "Write" }
          TabsTrigger(
            value: "preview",
            data: { action: "click->markdown-preview#fetchPreview" }
          ) { "Preview" }
        end

        TabsContent(value: "write") do
          textarea(
            name: "article[body]",
            class: "w-full min-h-[70vh] p-4 pb-2 font-mono text-sm border border-input rounded-lg bg-background text-foreground resize-none focus:outline-none focus:ring-2 focus:ring-ring",
            data: { markdown_preview_target: "input" },
            placeholder: "Write your article in markdown..."
          ) { plain @body }
        end

        TabsContent(value: "preview") do
          div(
            class: "min-h-[70vh] p-4 pb-2 border border-input rounded-lg bg-background prose prose-sm dark:prose-invert max-w-none",
            data: { markdown_preview_target: "preview" }
          ) do
            raw safe(MarkdownRenderer.render(@body)) if @body.present?
          end
        end
      end
    end
  end
end
