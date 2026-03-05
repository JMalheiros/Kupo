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
            Badge(variant: status_variant(@article.status)) { plain @article.status.capitalize }

            @article.categories.each do |category|
              Badge(variant: :secondary) { plain category.name }
            end
          end

          Heading(level: 1) { plain @article.title }

          p(class: "text-sm text-muted-foreground mt-2") do
            plain @article.created_at.strftime("%B %d, %Y")
          end
        end

        div(class: "article-body") do
          raw safe(MarkdownRenderer.render(@article.body))
        end
      end

      footer(class: "mt-8 pt-4 border-t border-border flex gap-4") do
        Link(
          href: helpers.edit_article_path(slug: @article.slug),
          variant: :outline,
          size: :sm,
          data: { turbo_frame: "modal" }
        ) { "Edit" }

        Link(
          href: helpers.export_article_path(slug: @article.slug),
          variant: :outline,
          size: :sm
        ) { "Export Markdown" }
      end
    end

    turbo_frame_tag("modal")
  end

  private

  def status_variant(status)
    case status
    when "published" then :green
    when "scheduled" then :yellow
    when "draft" then :gray
    end
  end
end
