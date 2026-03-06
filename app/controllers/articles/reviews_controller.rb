module Articles
  class ReviewsController < ApplicationController
    def create
      @article = Article.find_by!(slug: params[:slug])
      review = @article.article_reviews.create!

      ContentReviewJob.perform_later(review, Current.user)
      SeoReviewJob.perform_later(review, Current.user)

      redirect_to edit_article_url(slug: @article.slug)
    end

    def update_suggestion
      @article = Article.find_by!(slug: params[:slug])
      @suggestion = ReviewSuggestion.find(params[:id])

      if params[:status] == "accepted"
        apply_suggestion(@suggestion)
        @suggestion.update!(status: "accepted")
      else
        @suggestion.update!(status: "rejected")
      end

      render turbo_stream: turbo_stream.replace(
        "suggestion-#{@suggestion.id}",
        html: "<div id='suggestion-#{@suggestion.id}'>#{@suggestion.status}</div>"
      )
    end

    private

    def apply_suggestion(suggestion)
      article = suggestion.article_review.article
      return unless suggestion.original_text.present?

      case suggestion.category
      when "title"
        article.update!(title: suggestion.suggested_text)
      else
        updated_body = article.body.sub(suggestion.original_text, suggestion.suggested_text)
        article.update!(body: updated_body)
      end
    end
  end
end
