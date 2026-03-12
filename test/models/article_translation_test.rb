require "test_helper"

class ArticleTranslationTest < ActiveSupport::TestCase
  context "associations" do
    should belong_to(:article)
  end

  context "validations" do
    should validate_presence_of(:language)
    should validate_presence_of(:status)
    should validate_inclusion_of(:status).in_array(%w[pending completed failed])
    should validate_inclusion_of(:language).in_array(%w[en pt-BR])
  end

  should "default status to pending" do
    translation = create(:article_translation)
    assert_equal "pending", translation.status
  end

  should "default language to en" do
    translation = create(:article_translation)
    assert_equal "en", translation.language
  end

  should "enforce uniqueness on [article_id, language]" do
    article = create(:article)
    create(:article_translation, article: article, language: "en")
    assert_raises(ActiveRecord::RecordNotUnique) do
      ArticleTranslation.create!(article: article, language: "en", status: "pending")
    end
  end

  should "allow different languages for the same article" do
    article = create(:article)
    create(:article_translation, article: article, language: "en")
    translation_pt = ArticleTranslation.create!(article: article, language: "pt-BR", status: "pending")
    assert translation_pt.persisted?
  end
end
