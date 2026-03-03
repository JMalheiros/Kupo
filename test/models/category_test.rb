require "test_helper"

class CategoryTest < ActiveSupport::TestCase
  subject { build(:category) }

  context "validations" do
    should validate_presence_of(:name)
    should validate_uniqueness_of(:name)

    should "validate uniqueness of slug" do
      create(:category, name: "Ruby", slug: "ruby")
      duplicate = build(:category, name: "Other", slug: "ruby")
      assert_not duplicate.valid?
      assert_includes duplicate.errors[:slug], "has already been taken"
    end
  end

  context "slug generation" do
    should "auto-generate slug from name before validation" do
      category = build(:category, name: "Ruby on Rails", slug: nil)
      category.valid?
      assert_equal "ruby-on-rails", category.slug
    end

    should "not overwrite an existing slug" do
      category = build(:category, name: "Ruby", slug: "custom-slug")
      category.valid?
      assert_equal "custom-slug", category.slug
    end
  end

  context "associations" do
    should have_many(:article_categories).dependent(:destroy)
    should have_many(:articles).through(:article_categories)
  end
end
