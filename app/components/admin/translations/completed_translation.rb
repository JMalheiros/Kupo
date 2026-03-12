# frozen_string_literal: true

class Components::Admin::Translations::CompletedTranslation < Components::Base
  def initialize(article:, language:, translation:)
    @article = article
    @language = language
    @translation = translation
  end

  def view_template
    form(action: translate_article_path(slug: @article.slug), method: "post", class: "space-y-4") do
      input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)
      input(type: "hidden", name: "_method", value: "patch")
      input(type: "hidden", name: "language", value: @language)

      FormField do
        FormFieldLabel { "Translated Title" }
        Input(
          type: :text,
          name: "article_translation[title]",
          value: @translation.title
        )
      end

      div(class: "col-span-3") do
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
                name: "article_translation[body]",
                class: "w-full min-h-[40vh] p-4 pb-2 font-mono text-sm border border-input rounded-lg bg-background text-foreground resize-none focus:outline-none focus:ring-2 focus:ring-ring",
                data: { markdown_preview_target: "input" },
                placeholder: "Translated content..."
              ) { plain @translation.body }
            end

            TabsContent(value: "preview") do
              div(
                class: "min-h-[40vh] p-4 pb-2 border border-input rounded-lg bg-background prose prose-sm dark:prose-invert max-w-none",
                data: { markdown_preview_target: "preview" }
              ) do
                raw safe(MarkdownRenderer.render(@translation.body)) if @translation.body.present?
              end
            end
          end
        end
      end

      div(class: "flex justify-between items-center") do
        Link(
          href: export_translation_article_path(slug: @article.slug, language: @language),
          variant: :outline
        ) do
          plain "Export as Markdown"
        end

        Button(type: :submit) { "Save Translation" }
      end
    end
  end
end
