require "test_helper"

class Articles::PreviewsControllerTest < ActionDispatch::IntegrationTest
  context "unauthorized" do
    should "redirect preview to sign in" do
      article = create(:article, :draft)
      get preview_article_url(slug: article.slug)
      assert_response :redirect
    end
  end

  context "GET #preview (authenticated)" do
    setup do
      @user = create(:user)
      sign_in(@user)
      @article = create(:article, :draft)
    end

    should "render the article preview" do
      get preview_article_url(slug: @article.slug)
      assert_response :success
      assert_includes response.body, @article.title
    end
  end
end
