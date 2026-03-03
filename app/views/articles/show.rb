# frozen_string_literal: true

class Views::Articles::Show < Views::Base
  def initialize(article:, modal: false)
    @article = article
    @modal = modal
  end

  def view_template
    if @modal
      turbo_frame_tag("modal") do
        render Components::Modal.new do
          article_content
        end
      end
    else
      div(class: "max-w-3xl mx-auto px-4 py-8") do
        article_content
      end
    end
  end

  private

  def article_content
    article(class: "prose prose-lg dark:prose-invert max-w-none") do
      header(class: "mb-8") do
        div(class: "flex items-center gap-2 mb-4") do
          @article.categories.each do |category|
            span(class: "text-xs font-medium px-2 py-1 rounded-full bg-secondary text-secondary-foreground") do
              plain category.name
            end
          end
        end

        h1(class: "text-3xl font-bold text-foreground") { plain @article.title }

        p(class: "text-sm text-muted-foreground mt-2") do
          plain @article.published_at&.strftime("%B %d, %Y")
        end
      end

      div(class: "article-body") do
        raw safe(MarkdownRenderer.render(@article.body))
      end
    end
  end
end
