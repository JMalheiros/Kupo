# frozen_string_literal: true

class Components::Admin::Reviews::ReviewSuggestionCard < Components::Base
  def initialize(suggestion:, article:)
    @suggestion = suggestion
    @article = article
  end

  def view_template
    div(id: "suggestion-#{@suggestion.id}", class: "border border-border rounded-lg p-4 space-y-3") do
      div(class: "flex items-center justify-between") do
        Badge(variant: category_variant) { plain @suggestion.category.capitalize }
        if @suggestion.status != "pending"
          Badge(variant: @suggestion.status == "accepted" ? :green : :gray) do
            plain @suggestion.status.capitalize
          end
        end
      end

      Text(size: "sm", weight: "muted") { plain @suggestion.explanation }

      if @suggestion.original_text.present?
        div(class: "space-y-1") do
          div(class: "text-sm") do
            span(class: "font-medium text-destructive") { "- " }
            span(class: "line-through text-destructive/70") { plain @suggestion.original_text }
          end
          div(class: "text-sm") do
            span(class: "font-medium text-green-600 dark:text-green-400") { "+ " }
            span(class: "text-green-600 dark:text-green-400") { plain @suggestion.suggested_text }
          end
        end
      else
        div(class: "text-sm") do
          span(class: "font-medium text-green-600 dark:text-green-400") { "+ " }
          span(class: "text-green-600 dark:text-green-400") { plain @suggestion.suggested_text }
        end
      end

      if @suggestion.status == "pending" && @suggestion.process == "content"
        div(class: "flex gap-2 pt-1") do
          Form(
            action: article_review_suggestion_path(slug: @article.slug, id: @suggestion.id),
            method: "post"
          ) do
            Input(type: :hidden, name: "authenticity_token", value: form_authenticity_token)
            Input(type: :hidden, name: "_method", value: "patch")
            Input(type: :hidden, name: "status", value: "accepted")
            Button(type: :submit, variant: :outline, size: :sm) { "Accept" }
          end

          Form(
            action: article_review_suggestion_path(slug: @article.slug, id: @suggestion.id),
            method: "post"
          ) do
            Input(type: :hidden, name: "authenticity_token", value: form_authenticity_token)
            Input(type: :hidden, name: "_method", value: "patch")
            Input(type: :hidden, name: "status", value: "rejected")
            Button(type: :submit, variant: :ghost, size: :sm, class: "text-muted-foreground") { "Reject" }
          end
        end
      end
    end
  end

  private

  def category_variant
    case @suggestion.category
    when "grammar", "clarity" then :yellow
    when "tone", "structure" then :blue
    when "title", "seo" then :green
    when "summary", "tags" then :gray
    end
  end
end
