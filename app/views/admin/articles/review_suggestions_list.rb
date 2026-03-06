# frozen_string_literal: true

class Views::Admin::Articles::ReviewSuggestionsList < Views::Base
  def initialize(suggestions:, article:)
    @suggestions = suggestions
    @article = article
  end

  def view_template
    if @suggestions.any?
      div(class: "space-y-3") do
        @suggestions.each do |suggestion|
          render Views::Admin::Articles::ReviewSuggestionCard.new(
            suggestion: suggestion,
            article: @article
          )
        end
      end
    else
      p(class: "text-sm text-muted-foreground") { "No suggestions found — your article looks good!" }
    end
  end
end
