# frozen_string_literal: true

class Views::Articles::Preview::Show < Views::Base
  def initialize(article:)
    @article = article
  end

  def view_template
    div(class: "max-w-3xl mx-auto px-4 py-8") do
      article(class: "prose prose-lg dark:prose-invert max-w-none") do
        header(class: "mb-8") do
          div(class: "flex items-center gap-2 mb-4") do
            render Components::Admin::StatusBadge.new(status: @article.status)

            @article.categories.each do |category|
              span(class: "text-xs font-medium px-2 py-1 rounded-full bg-secondary text-secondary-foreground") do
                plain category.name
              end
            end
          end

          h1(class: "text-3xl font-bold text-foreground") { plain @article.title }

          p(class: "text-sm text-muted-foreground mt-2") do
            plain @article.created_at.strftime("%B %d, %Y")
          end
        end

        div(class: "article-body") do
          raw safe(MarkdownRenderer.render(@article.body))
        end
      end

      footer(class: "mt-8 pt-4 border-t border-border flex gap-4") do
        a(
          href: helpers.edit_article_path(slug: @article.slug),
          class: "px-4 py-2 text-sm border border-input rounded-lg hover:bg-accent transition-colors",
          data: { turbo_frame: "modal" }
        ) { "Edit" }

        a(
          href: helpers.export_article_path(slug: @article.slug),
          class: "px-4 py-2 text-sm border border-input rounded-lg hover:bg-accent transition-colors"
        ) { "Export Markdown" }
      end
    end

    turbo_frame_tag("modal")
  end
end
