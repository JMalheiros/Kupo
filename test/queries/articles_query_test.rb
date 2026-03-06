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

  # Sort tests
  should "sort by newest (default)" do
    old = create(:article, :published, published_at: 2.days.ago)
    recent = create(:article, :published, published_at: 1.hour.ago)

    result = ArticlesQuery.new(params: {}).call
    published = result.select { |a| a.status == "published" }
    assert published.index(recent) < published.index(old)
  end

  should "sort by oldest when sort param is oldest" do
    old = create(:article, :published, published_at: 2.days.ago)
    recent = create(:article, :published, published_at: 1.hour.ago)

    result = ArticlesQuery.new(params: { sort: "oldest" }).call
    published = result.select { |a| a.status == "published" }
    assert published.index(old) < published.index(recent)
  end

  # Pagination tests
  should "return first page of results with default page size" do
    create_list(:article, 12, :published)

    result = ArticlesQuery.new(params: { status: "published" }).call
    assert_equal 10, result.size
  end

  should "return second page of results" do
    create_list(:article, 12, :published)

    result = ArticlesQuery.new(params: { status: "published", page: "2" }).call
    assert_equal 3, result.size
  end

  should "return total count for pagination" do
    create_list(:article, 12, :published)

    query = ArticlesQuery.new(params: { status: "published" })
    query.call
    assert_equal 13, query.total_count
  end

  should "return total pages" do
    create_list(:article, 22, :published)

    query = ArticlesQuery.new(params: { status: "published" })
    query.call
    assert_equal 3, query.total_pages
  end
end
