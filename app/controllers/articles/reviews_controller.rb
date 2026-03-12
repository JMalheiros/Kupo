module Articles
  class ReviewsController < ApplicationController
    def create
      @article = Article.find_by!(slug: params[:slug])
      review = @article.article_review

      if review
        review.review_suggestions.destroy_all
        review.update!(content_status: "pending", seo_status: "pending")
      else
        review = @article.create_article_review!
      end

      ContentReviewJob.perform_later(review, Current.user)
      SeoReviewJob.perform_later(review, Current.user)

      @article.reload
      render turbo_stream: turbo_stream.replace(
        "article-reviews",
        Components::Admin::Reviews.new(article: @article)
      )
    end

    def update_suggestion
      @article = Article.find_by!(slug: params[:slug])
      @suggestion = ReviewSuggestion.find(params[:id])
      @categories = Category.all

      if params[:status] == "accepted"
        apply_suggestion(@suggestion)
        @suggestion.update!(status: "accepted")
        @article.reload
      else
        @suggestion.update!(status: "rejected")
      end

      render turbo_stream: [
        turbo_stream.replace(
          "suggestion-#{@suggestion.id}",
          Components::Admin::Reviews::ReviewSuggestionCard.new(
            suggestion: @suggestion,
            article: @article
          )
        ),
        turbo_stream.replace(
          "modal",
          Views::Admin::Articles::Form.new(article: @article, categories: @categories)
        )
      ]
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
