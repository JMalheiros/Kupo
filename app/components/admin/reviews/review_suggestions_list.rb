# frozen_string_literal: true

class Components::Admin::Reviews::ReviewSuggestionsList < Components::Base
  def initialize(suggestions:, article:)
    @suggestions = suggestions
    @article = article
  end

  def view_template
    if @suggestions.any?
      div(class: "space-y-3") do
        @suggestions.each do |suggestion|
          render Components::Admin::Reviews::ReviewSuggestionCard.new(
            suggestion: suggestion,
            article: @article
          )
        end
      end
    else
      Text(size: "sm", weight: "muted") { "No suggestions found — your article looks good!" }
    end
  end
end
