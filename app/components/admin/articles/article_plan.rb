# frozen_string_literal: true

class Components::Admin::Articles::ArticlePlan < Components::Base
  def initialize(article:, generating: false)
    @article = article
    @generating = generating
  end

  def view_template
    div(id: "article-plan-editor") do
      if @article.persisted?
        div(class: "flex items-center justify-end mb-4 gap-3") do
          if @generating
            p(class: "text-sm text-muted-foreground animate-pulse") { "Generating plan..." }
            Button(variant: :outline, disabled: true) do
              Lucide::LoaderCircle(class: "h-4 w-4 mr-1.5 inline-block animate-spin")
              plain "Generate Plan"
            end
          else
            Link(
              href: generate_plan_article_path(slug: @article.slug),
              variant: :outline,
              data: { turbo_method: :post }
            ) do
              Lucide::Sparkles(variant: :filled, class: "h-4 w-4 mr-1.5 inline-block")
              plain "Generate Plan"
            end
          end
        end
      end

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
              name: "article[plan]",
              class: "min-h-[40vh] p-4 pb-2 font-mono rounded-lg text-foreground resize-none",
              data: { markdown_preview_target: "input" },
              placeholder: "Outline your article structure and key points..."
            ) { plain @article.plan }
          end

          TabsContent(value: "preview") do
            div(
              class: "min-h-[40vh] p-4 pb-2 border border-input rounded-lg bg-background prose prose-sm dark:prose-invert max-w-none",
              data: { markdown_preview_target: "preview" }
            ) do
              raw safe(MarkdownRenderer.render(@article.plan)) if @article.plan.present?
            end
          end
        end
      end
    end
  end
end
