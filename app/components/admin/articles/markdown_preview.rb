# frozen_string_literal: true

class Components::Admin::Articles::MarkdownPreview < Components::Base
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
          Textarea(
            name: "article[body]",
            class: "min-h-[40vh] p-4 pb-2 font-mono rounded-lg text-foreground resize-none",
            data: { markdown_preview_target: "input" },
            placeholder: "Write your article in markdown..."
          ) { plain @body }
        end

        TabsContent(value: "preview") do
          div(
            class: "min-h-[40vh] p-4 pb-2 border border-input rounded-lg bg-background prose prose-sm dark:prose-invert max-w-none",
            data: { markdown_preview_target: "preview" }
          ) do
            raw safe(MarkdownRenderer.render(@body)) if @body.present?
          end
        end
      end
    end
  end
end
