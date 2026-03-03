require "test_helper"

class ArticlesControllerTest < ActionDispatch::IntegrationTest
  context "GET #index" do
    should "show only published articles" do
      published = create(:article, :published)
      draft = create(:article, :draft)
      scheduled = create(:article, :scheduled)

      get root_url
      assert_response :success
      assert_includes response.body, published.title
      assert_not_includes response.body, draft.title
      assert_not_includes response.body, scheduled.title
    end

    should "filter articles by category" do
      category = create(:category, name: "Ruby")
      in_category = create(:article, :published, categories: [category])
      other = create(:article, :published)

      get root_url, params: { category: category.slug }
      assert_response :success
      assert_includes response.body, in_category.title
      assert_not_includes response.body, other.title
    end
  end

  context "GET #show" do
    should "show a published article" do
      article = create(:article, :published)
      get article_url(slug: article.slug)
      assert_response :success
      assert_includes response.body, article.title
    end

    should "return 404 for draft article" do
      article = create(:article, :draft)
      get article_url(slug: article.slug)
      assert_response :not_found
    end

    should "return 404 for scheduled article" do
      article = create(:article, :scheduled)
      get article_url(slug: article.slug)
      assert_response :not_found
    end
  end
end
