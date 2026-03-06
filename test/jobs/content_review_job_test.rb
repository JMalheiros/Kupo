require "test_helper"

class ContentReviewJobTest < ActiveSupport::TestCase
  setup do
    @article = create(:article, :draft)
    @review = create(:article_review, article: @article)
    @user = create(:user)
    ContentReviewJob.any_instance.stubs(:broadcast_results)
    ContentReviewJob.any_instance.stubs(:broadcast_error)
  end

  should "create review suggestions and update status to completed" do
    fake_suggestions = [
      { category: "grammar", original_text: "bad text", suggested_text: "good text", explanation: "Fix" }
    ]

    ReviewService.any_instance.stubs(:content_review).returns(fake_suggestions)

    ContentReviewJob.perform_now(@review, @user)

    @review.reload
    assert_equal "completed", @review.content_status
    assert_equal 1, @review.review_suggestions.where(process: "content").count
  end

  should "set status to failed when service raises" do
    ReviewService.any_instance.stubs(:content_review).raises(StandardError.new("API error"))

    ContentReviewJob.perform_now(@review, @user)

    @review.reload
    assert_equal "failed", @review.content_status
  end
end
