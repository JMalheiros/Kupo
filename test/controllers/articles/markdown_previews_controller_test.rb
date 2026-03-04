require "test_helper"

class Articles::MarkdownPreviewsControllerTest < ActionDispatch::IntegrationTest
  context "unauthenticated" do
    should "redirect markdown_preview to sign in" do
      post markdown_preview_articles_url, params: { body: "# Hello" }
      assert_response :redirect
    end
  end

  context "POST #markdown_preview (authenticated)" do
    setup do
      @user = create(:user)
      sign_in(@user)
    end

    should "render markdown as HTML" do
      post markdown_preview_articles_url, params: { body: "# Hello\n\n**Bold** text" }
      assert_response :success
      assert_includes response.body, "<h1>Hello</h1>"
      assert_includes response.body, "<strong>Bold</strong>"
    end
  end
end