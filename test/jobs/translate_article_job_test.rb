require "test_helper"

class TranslateArticleJobTest < ActiveSupport::TestCase
  setup do
    @article = create(:article, :draft, title: "Meu Artigo", body: "Conteudo em portugues.")
    @user = create(:user)
    TranslateArticleJob.any_instance.stubs(:broadcast_translation)
    TranslateArticleJob.any_instance.stubs(:broadcast_error)
  end

  should "create article translation and set status to completed" do
    fake_result = { "title" => "My Article", "body" => "Content in English." }
    TranslationService.any_instance.stubs(:translate).returns(fake_result)

    assert_difference("ArticleTranslation.count", 1) do
      TranslateArticleJob.perform_now(@article, @user, "en")
    end

    translation = @article.article_translations.find_by(language: "en")
    assert_equal "completed", translation.status
    assert_equal "My Article", translation.title
    assert_equal "Content in English.", translation.body
  end

  should "create translations for different languages independently" do
    fake_result_en = { "title" => "My Article", "body" => "English content." }
    fake_result_pt = { "title" => "Meu Artigo", "body" => "Conteudo em portugues." }

    TranslationService.any_instance.stubs(:translate).returns(fake_result_en).then.returns(fake_result_pt)

    assert_difference("ArticleTranslation.count", 2) do
      TranslateArticleJob.perform_now(@article, @user, "en")
      TranslateArticleJob.perform_now(@article, @user, "pt-BR")
    end

    assert_equal 2, @article.article_translations.count
  end

  should "overwrite existing translation on re-run for same language" do
    existing = create(:article_translation, :completed, article: @article, language: "en")
    fake_result = { "title" => "New Title", "body" => "New body." }
    TranslationService.any_instance.stubs(:translate).returns(fake_result)

    assert_no_difference("ArticleTranslation.count") do
      TranslateArticleJob.perform_now(@article, @user, "en")
    end

    existing.reload
    assert_equal "completed", existing.status
    assert_equal "New Title", existing.title
    assert_equal "New body.", existing.body
  end

  should "set status to failed when service returns nil" do
    TranslationService.any_instance.stubs(:translate).returns(nil)

    TranslateArticleJob.perform_now(@article, @user, "en")

    translation = @article.article_translations.find_by(language: "en")
    assert_equal "failed", translation.status
  end

  should "set status to failed when service raises" do
    TranslationService.any_instance.stubs(:translate).raises(StandardError.new("API error"))

    TranslateArticleJob.perform_now(@article, @user, "en")

    translation = @article.article_translations.find_by(language: "en")
    assert_equal "failed", translation.status
  end
end
