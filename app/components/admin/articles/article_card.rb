# frozen_string_literal: true

class Components::Admin::Articles::ArticleCard < Components::Base
  def initialize(article:)
    @article = article
  end

  def view_template
    Card do
      div(class: "flex-1") do
        CardHeader(class: "flex flex-row items-center gap-3 space-y-0 pb-2") do
          Badge(variant: status_variant(@article.status)) do
            if @article.status == "publishing"
              span(class: "animate-pulse") { plain "Publishing" }
            else
              plain @article.status.capitalize
            end
          end
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
          href: edit_article_path(slug: @article.slug),
          variant: :ghost,
          size: :md,
          data: { turbo_frame: "modal" }
        ) { "Edit" }

        Link(
          href: export_article_path(slug: @article.slug),
          variant: :ghost,
          size: :md,
          data: { turbo: "false" }
        ) { "Export" }

        render Components::Admin::Articles::PublishSheet.new(article: @article) unless %w[published publishing].include?(@article.status)

        form(action: article_path(slug: @article.slug), method: "post") do
          input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)
          input(type: "hidden", name: "_method", value: "delete")
          Button(
            type: :submit,
            variant: :ghost,
            size: :md,
            class: "text-destructive hover:text-destructive/80",
            data: { turbo_confirm: "Are you sure you want to delete this article?" }
          ) { "Delete" }
        end
      end
    end
  end

  private

  def status_variant(status)
    case status
    when "published" then :green
    when "scheduled" then :yellow
    when "publishing" then :blue
    when "draft" then :gray
    end
  end
end
