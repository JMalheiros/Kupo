require "test_helper"

class Articles::TranslationsControllerTest < ActionDispatch::IntegrationTest
  context "unauthenticated" do
    should "redirect to sign in for create" do
      article = create(:article, :draft)
      post translate_article_url(slug: article.slug), params: { language: "en" }
      assert_response :redirect
    end

    should "redirect to sign in for update" do
      article = create(:article, :draft)
      patch translate_article_url(slug: article.slug), params: { language: "en" }
      assert_response :redirect
    end

    should "redirect to sign in for export" do
      article = create(:article, :draft)
      get export_translation_article_url(slug: article.slug), params: { language: "en" }
      assert_response :redirect
    end
  end

  context "POST #create (authenticated)" do
    setup do
      @user = create(:user)
      sign_in(@user)
      @article = create(:article, :draft)
    end

    should "enqueue TranslateArticleJob and respond with success" do
      assert_enqueued_jobs 1, only: TranslateArticleJob do
        post translate_article_url(slug: @article.slug), params: { language: "en" }
      end

      assert_response :success
    end

    should "create article_translation record in pending state" do
      assert_difference("ArticleTranslation.count", 1) do
        post translate_article_url(slug: @article.slug), params: { language: "en" }
      end

      translation = @article.article_translations.find_by(language: "en")
      assert_equal "pending", translation.status
    end

    should "accept pt-BR as language" do
      assert_difference("ArticleTranslation.count", 1) do
        post translate_article_url(slug: @article.slug), params: { language: "pt-BR" }
      end

      translation = @article.article_translations.find_by(language: "pt-BR")
      assert_equal "pending", translation.status
    end

    should "reuse existing translation on re-translate" do
      create(:article_translation, :completed, article: @article, language: "en")

      assert_no_difference("ArticleTranslation.count") do
        post translate_article_url(slug: @article.slug), params: { language: "en" }
      end

      translation = @article.article_translations.find_by(language: "en")
      assert_equal "pending", translation.status
    end
  end

  context "PATCH #update (authenticated)" do
    setup do
      @user = create(:user)
      sign_in(@user)
      @article = create(:article, :draft)
      @translation = create(:article_translation, :completed, article: @article, language: "en")
    end

    should "update translation title and body" do
      patch translate_article_url(slug: @article.slug), params: {
        language: "en",
        article_translation: { title: "Updated Title", body: "Updated body." }
      }

      @translation.reload
      assert_equal "Updated Title", @translation.title
      assert_equal "Updated body.", @translation.body
      assert_response :success
    end
  end

  context "GET #export (authenticated)" do
    setup do
      @user = create(:user)
      sign_in(@user)
      @article = create(:article, :draft)
      @translation = create(:article_translation, :completed, article: @article, language: "en")
    end

    should "return markdown file" do
      get export_translation_article_url(slug: @article.slug), params: { language: "en" }

      assert_response :success
      assert_equal "text/markdown", response.content_type
      assert_includes response.body, @translation.title
      assert_includes response.body, @translation.body
    end
  end
end
