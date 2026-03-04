require "test_helper"

class Articles::ExportsControllerTest < ActionDispatch::IntegrationTest
  context "unauthenticated" do
    should "redirect export to sign in" do
      article = create(:article, :draft)
      get export_article_url(slug: article.slug)
      assert_response :redirect
    end
  end

  context "GET #export (authenticated)" do
    setup do
      @user = create(:user)
      sign_in(@user)
    end

    should "download the article as markdown" do
      article = create(:article, :published, title: "My Article", body: "## Hello\n\nSome content here.")

      get export_article_url(slug: article.slug)

      assert_response :success
      assert_equal "text/markdown", response.content_type
      assert_match "attachment", response.headers["Content-Disposition"]
      assert_includes response.headers["Content-Disposition"], "#{article.slug}.md"
      assert_includes response.body, "# My Article"
      assert_includes response.body, "## Hello"
      assert_includes response.body, "Some content here."
    end
  end
end
