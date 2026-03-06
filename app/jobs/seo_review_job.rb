class SeoReviewJob < ApplicationJob
  queue_as :default

  def perform(review, user)
    suggestions = ReviewService.new.seo_review(review.article)

    suggestions.each do |s|
      review.review_suggestions.create!(
        process: "seo",
        category: s[:category],
        original_text: s[:original_text],
        suggested_text: s[:suggested_text],
        explanation: s[:explanation]
      )
    end

    review.update!(seo_status: "completed")
    broadcast_results(review, user, "seo")
  rescue => e
    Rails.logger.error("SeoReviewJob failed: #{e.class} - #{e.message}")
    review.update!(seo_status: "failed")
    broadcast_error(user, "seo")
  end

  private

  def broadcast_results(review, user, process)
    suggestions = review.review_suggestions.where(process: process)

    html = ApplicationController.render(
      Views::Admin::Articles::ReviewSuggestionsList.new(
        suggestions: suggestions,
        article: review.article
      ),
      layout: false
    )

    Turbo::StreamsChannel.broadcast_replace_to(
      user,
      target: "#{process}-review-results",
      html: html
    )
  end

  def broadcast_error(user, process)
    Turbo::StreamsChannel.broadcast_replace_to(
      user,
      target: "#{process}-review-results",
      html: "<p class='text-sm text-destructive'>Review failed. Please try again.</p>"
    )
  end
end
