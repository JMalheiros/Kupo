require "test_helper"

class PublishArticleJobTest < ActiveSupport::TestCase
  should "publish a scheduled article" do
    article = create(:article, :scheduled, published_at: 1.minute.ago)
    PublishArticleJob.perform_now(article)

    article.reload
    assert_equal "published", article.status
  end

  should "not publish an article that is no longer scheduled" do
    article = create(:article, :draft)
    PublishArticleJob.perform_now(article)

    article.reload
    assert_equal "draft", article.status
  end

  should "not publish an article that is already published" do
    article = create(:article, :published)
    original_published_at = article.published_at
    PublishArticleJob.perform_now(article)

    article.reload
    assert_equal "published", article.status
    assert_equal original_published_at.to_i, article.published_at.to_i
  end
end
