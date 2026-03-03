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

  context "authentication required" do
    should "redirect new to sign in when not authenticated" do
      get new_article_url
      assert_response :redirect
    end

    should "redirect create to sign in when not authenticated" do
      post articles_url, params: { article: { title: "Test", body: "Content" } }
      assert_response :redirect
    end

    should "redirect edit to sign in when not authenticated" do
      article = create(:article, :draft)
      get edit_article_url(slug: article.slug)
      assert_response :redirect
    end

    should "redirect update to sign in when not authenticated" do
      article = create(:article, :draft)
      patch article_url(slug: article.slug), params: { article: { title: "Updated" } }
      assert_response :redirect
    end

    should "redirect destroy to sign in when not authenticated" do
      article = create(:article, :draft)
      delete article_url(slug: article.slug)
      assert_response :redirect
    end
  end

  context "GET #new (authenticated)" do
    setup do
      @user = create(:user)
      sign_in(@user)
    end

    should "render new article form" do
      get new_article_url
      assert_response :success
    end
  end

  context "POST #create (authenticated)" do
    setup do
      @user = create(:user)
      sign_in(@user)
    end

    should "create a draft article" do
      assert_difference("Article.count", 1) do
        post articles_url, params: { article: { title: "New Post", body: "# Content", category_ids: [] } }
      end

      article = Article.last
      assert_equal "draft", article.status
      assert_redirected_to article_url(slug: article.slug)
    end

    should "not create article with invalid params" do
      assert_no_difference("Article.count") do
        post articles_url, params: { article: { title: "", body: "" } }
      end
      assert_response :unprocessable_entity
    end
  end

  context "PATCH #update (authenticated)" do
    setup do
      @user = create(:user)
      sign_in(@user)
      @article = create(:article, :draft)
    end

    should "update the article" do
      patch article_url(slug: @article.slug), params: { article: { title: "Updated Title" } }
      @article.reload
      assert_equal "Updated Title", @article.title
      assert_redirected_to article_url(slug: @article.slug)
    end
  end

  context "DELETE #destroy (authenticated)" do
    setup do
      @user = create(:user)
      sign_in(@user)
      @article = create(:article, :draft)
    end

    should "destroy the article" do
      assert_difference("Article.count", -1) do
        delete article_url(slug: @article.slug)
      end
      assert_redirected_to root_url
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
      assert_redirected_to article_url(slug: article.slug)
    end

    should "schedule an article for future publication" do
      article = create(:article, :draft)
      future_time = 2.days.from_now.iso8601
      post publish_article_url(slug: article.slug), params: { publish_action: "schedule", published_at: future_time }

      article.reload
      assert_equal "scheduled", article.status
      assert_redirected_to article_url(slug: article.slug)
    end
  end

  context "POST #publish (unauthenticated)" do
    should "require authentication" do
      article = create(:article, :draft)
      post publish_article_url(slug: article.slug), params: { publish_action: "now" }
      assert_response :redirect
    end
  end

  context "POST #preview (authenticated)" do
    setup do
      @user = create(:user)
      sign_in(@user)
    end

    should "render markdown as HTML" do
      post preview_articles_url, params: { body: "# Hello\n\n**Bold** text" }
      assert_response :success
      assert_includes response.body, "<h1>Hello</h1>"
      assert_includes response.body, "<strong>Bold</strong>"
    end
  end

  context "POST #preview (unauthenticated)" do
    should "require authentication" do
      post preview_articles_url, params: { body: "# Hello" }
      assert_response :redirect
    end
  end
end
