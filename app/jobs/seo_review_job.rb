class SeoReviewJob < ApplicationJob
  queue_as :default

  def perform(review, user)
    suggestions = ReviewService.new(user).seo_review(review.article)

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
    broadcast_button(review, user) unless review.reload.content_status == "pending"
  rescue => e
    Rails.logger.error("SeoReviewJob failed: #{e.class} - #{e.message}")
    review.update!(seo_status: "failed")
    broadcast_error(user, "seo")
    broadcast_button(review, user) unless review.reload.content_status == "pending"
  end

  private

  def broadcast_results(review, user, process)
    suggestions = review.review_suggestions.where(process: process)

    html = ApplicationController.render(
      Components::Admin::Reviews::ReviewSuggestionsList.new(
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

  def broadcast_button(review, user)
    html = ApplicationController.render(
      Components::Admin::Reviews.new(article: review.article),
      layout: false
    )

    Turbo::StreamsChannel.broadcast_replace_to(
      user,
      target: "article-reviews",
      html: html
    )
  end
end
