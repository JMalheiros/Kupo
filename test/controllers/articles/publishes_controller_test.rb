require "test_helper"

class Articles::PublishesControllerTest < ActionDispatch::IntegrationTest
  context "unauthenticated" do
    should "redirect publish to sign in" do
      article = create(:article, :draft)
      post publish_article_url(slug: article.slug), params: { publish_action: "now" }
      assert_response :redirect
    end
  end

  context "POST #publish (authenticated)" do
    setup do
      @user = create(:user)
      sign_in(@user)
    end

    should "publish an article immediately" do
      article = create(:article, :draft)
      post publish_article_url(slug: article.slug), params: { publish_action: "now" }

      article.reload
      assert_equal "published", article.status
      assert_not_nil article.published_at
      assert_redirected_to preview_article_url(slug: article.slug)
    end

    should "schedule an article for future publication" do
      article = create(:article, :draft)
      future_time = 2.days.from_now.iso8601
      post publish_article_url(slug: article.slug), params: { publish_action: "schedule", published_at: future_time }

      article.reload
      assert_equal "scheduled", article.status
      assert_redirected_to preview_article_url(slug: article.slug)
    end
  end
end
