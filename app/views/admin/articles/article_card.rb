# frozen_string_literal: true

class Views::Admin::Articles::ArticleCard < Views::Base
  def initialize(article:)
    @article = article
  end

  def view_template
    Card do
      div(class: "flex-1") do
        CardHeader(class: "flex flex-row items-center gap-3 space-y-0 pb-2") do
          Badge(variant: status_variant(@article.status)) { plain @article.status.capitalize }
          CardTitle { plain @article.title }
        end

        CardContent(class: "py-0") do
          CardDescription do
            if @article.published_at
              plain "#{@article.status == 'scheduled' ? 'Scheduled for' : 'Published'} #{@article.published_at.strftime('%B %d, %Y at %H:%M')}"
            else
              plain "Draft"
            end
          end
        end
      end # div

      CardFooter(class: "flex justify-end gap-2") do
        Link(
          href: helpers.edit_article_path(slug: @article.slug),
          variant: :ghost,
          size: :md,
          data: { turbo_frame: "modal" }
        ) { "Edit" }

        Button(
          variant: :ghost,
          size: :md,
          formaction: helpers.article_path(slug: @article.slug),
          formmethod: "post",
          name: "_method",
          value: "delete",
          class: "text-destructive hover:text-destructive/80",
          data: { turbo_confirm: "Are you sure you want to delete this article?" }
        ) { "Delete" }
      end
    end
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
