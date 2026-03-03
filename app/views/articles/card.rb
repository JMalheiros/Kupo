# frozen_string_literal: true

class Views::Articles::Card < Views::Base
  def initialize(article:)
    @article = article
  end

  def view_template
    a(
      href: helpers.article_path(slug: @article.slug),
      class: "block p-6 rounded-lg border border-border hover:border-primary transition-colors",
      data: { turbo_frame: "modal", turbo_action: "advance" }
    ) do
      div(class: "flex items-center gap-2 mb-2") do
        @article.categories.each do |category|
          span(class: "text-xs font-medium px-2 py-1 rounded-full bg-secondary text-secondary-foreground") do
            plain category.name
          end
        end
      end

      h2(class: "text-xl font-semibold text-foreground mb-2") { plain @article.title }

      p(class: "text-sm text-muted-foreground") do
        plain @article.published_at&.strftime("%B %d, %Y")
      end

      p(class: "text-muted-foreground mt-2 line-clamp-3") do
        plain @article.body.truncate(200)
      end
    end
  end
end
