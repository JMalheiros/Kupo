# frozen_string_literal: true

class Components::Admin::Reviews < Components::Base
  def initialize(article:)
    @article = article
    @latest_review = @article.article_review
  end

  def view_template
    div(id: "article-reviews", class: "space-y-6 py-4") do
      div(id: "review-button") do
        if @article.persisted?
          div(class: "flex items-center justify-center gap-3") do
            if review_in_progress?
              p(class: "text-sm text-muted-foreground animate-pulse") { "Reviewing article..." }
              Button(disabled: true) do
                Lucide::LoaderCircle(class: "h-4 w-4 mr-1.5 inline-block animate-spin")
                plain "Review Article"
              end
            else
              Form(action: review_article_path(slug: @article.slug), method: "post") do
                Input(type: :hidden, name: "authenticity_token", value: form_authenticity_token)
                Button(type: :submit) do
                  Lucide::Sparkles(variant: :filled, class: "h-4 w-4 mr-1.5 inline-block")
                  plain "Review Article"
                end
              end
            end
          end
        else
          Text(size: "sm", weight: "muted", class: "text-center") { "Save the article first to enable AI review." }
        end
      end

      # Content Review Section
      div do
        Heading(level: 3, class: "mb-3") { "Content Review" }
        Text(size: "sm", weight: "muted", class: "mb-3") { "Grammar, clarity, tone, and structure" }
        div(id: "content-review-results") do
          if @latest_review
            render_section_status("content")
          else
            Text(size: "sm", weight: "muted") { "No review yet." }
          end
        end
      end

      # SEO Review Section
      div do
        Heading(level: 3, class: "mb-3") { "SEO & Metadata Review" }
        Text(size: "sm", weight: "muted", class: "mb-3") { "Title, SEO, summaries, and tags" }
        div(id: "seo-review-results") do
          if @latest_review
            render_section_status("seo")
          else
            Text(size: "sm", weight: "muted") { "No review yet." }
          end
        end
      end
    end
  end

  private

  def review_in_progress?
    @latest_review && (@latest_review.content_status == "pending" || @latest_review.seo_status == "pending")
  end

  def render_section_status(process)
    status = process == "content" ? @latest_review.content_status : @latest_review.seo_status

    case status
    when "pending"
      div(class: "flex items-center gap-2") do
        Text(size: "sm", weight: "muted", class: "animate-pulse") { "Analyzing..." }
      end
    when "completed"
      suggestions = @latest_review.review_suggestions.where(process: process)
      render Components::Admin::Reviews::ReviewSuggestionsList.new(
        suggestions: suggestions,
        article: @article
      )
    when "failed"
      Alert(variant: :destructive) do
        AlertTitle { "Review failed" }
        AlertDescription { "Please try again." }
      end
    end
  end
end
