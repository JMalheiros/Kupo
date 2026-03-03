require "test_helper"

class ArticleCategoryTest < ActiveSupport::TestCase
  subject { build(:article_category) }

  context "associations" do
    should belong_to(:article)
    should belong_to(:category)
  end

  context "validations" do
    should "enforce uniqueness of article and category pair" do
      article = create(:article)
      category = create(:category)
      create(:article_category, article: article, category: category)

      duplicate = build(:article_category, article: article, category: category)
      assert_not duplicate.valid?
    end
  end
end
