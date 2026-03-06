require "test_helper"

class ArticleReviewTest < ActiveSupport::TestCase
  context "associations" do
    should belong_to(:article)
    should have_many(:review_suggestions).dependent(:destroy)
  end

  context "validations" do
    should validate_presence_of(:content_status)
    should validate_presence_of(:seo_status)
    should validate_inclusion_of(:content_status).in_array(%w[pending completed failed])
    should validate_inclusion_of(:seo_status).in_array(%w[pending completed failed])
  end

  should "default statuses to pending" do
    review = create(:article_review)
    assert_equal "pending", review.content_status
    assert_equal "pending", review.seo_status
  end
end
