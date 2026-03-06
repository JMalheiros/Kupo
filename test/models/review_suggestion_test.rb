require "test_helper"

class ReviewSuggestionTest < ActiveSupport::TestCase
  context "associations" do
    should belong_to(:article_review)
  end

  context "validations" do
    should validate_presence_of(:process)
    should validate_presence_of(:category)
    should validate_presence_of(:suggested_text)
    should validate_presence_of(:explanation)
    should validate_presence_of(:status)
    should validate_inclusion_of(:process).in_array(%w[content seo])
    should validate_inclusion_of(:category).in_array(%w[grammar clarity tone structure title seo summary tags])
    should validate_inclusion_of(:status).in_array(%w[pending accepted rejected])
  end

  should "default status to pending" do
    suggestion = create(:review_suggestion)
    assert_equal "pending", suggestion.status
  end
end
