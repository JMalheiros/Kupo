require "test_helper"

class SeoReviewJobTest < ActiveSupport::TestCase
  setup do
    @article = create(:article, :draft)
    @review = create(:article_review, article: @article)
    @user = create(:user)
    SeoReviewJob.any_instance.stubs(:broadcast_results)
    SeoReviewJob.any_instance.stubs(:broadcast_error)
  end

  should "create review suggestions and update status to completed" do
    fake_suggestions = [
      { category: "title", original_text: "Old Title", suggested_text: "New Title", explanation: "Better" }
    ]

    ReviewService.any_instance.stubs(:seo_review).returns(fake_suggestions)

    SeoReviewJob.perform_now(@review, @user)

    @review.reload
    assert_equal "completed", @review.seo_status
    assert_equal 1, @review.review_suggestions.where(process: "seo").count
  end

  should "set status to failed when service raises" do
    ReviewService.any_instance.stubs(:seo_review).raises(StandardError.new("API error"))

    SeoReviewJob.perform_now(@review, @user)

    @review.reload
    assert_equal "failed", @review.seo_status
  end
end
