require "test_helper"

class ArticlesQueryTest < ActiveSupport::TestCase
  setup do
    @category = create(:category, name: "Ruby")
    @published = create(:article, :published, categories: [ @category ])
    @draft = create(:article, :draft)
    @scheduled = create(:article, :scheduled)
  end

  should "return all articles ordered by most recent" do
    result = ArticlesQuery.new(params: {}).call
    assert_includes result, @published
    assert_includes result, @draft
    assert_includes result, @scheduled
  end

  should "filter by category" do
    other = create(:article, :published)

    result = ArticlesQuery.new(params: { category: @category.slug }).call

    assert_includes result, @published
    assert_not_includes result, other
  end

  should "filter by status" do
    result = ArticlesQuery.new(params: { status: "draft" }).call

    assert_not_includes result, @published
    assert_includes result, @draft
    assert_not_includes result, @scheduled
  end

  should "filter by category and status combined" do
    draft_in_category = create(:article, :draft, categories: [ @category ])

    result = ArticlesQuery.new(params: { category: @category.slug, status: "draft" }).call

    assert_equal [ draft_in_category ], result.to_a
  end
end
