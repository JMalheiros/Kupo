# frozen_string_literal: true

require "test_helper"

class PublishArticleJobTest < ActiveSupport::TestCase
  should "publish a publishing article and set status to published" do
    article = create(:article, :publishing)
    user = create(:user)

    PublishArticleJob.perform_now(article, user)

    article.reload
    assert_equal "published", article.status
  end

  should "publish a scheduled article by transitioning through publishing to published" do
    article = create(:article, :scheduled, published_at: 1.minute.ago)
    user = create(:user)

    PublishArticleJob.perform_now(article, user)

    article.reload
    assert_equal "published", article.status
  end

  should "skip Hugo push when HUGO_REPO_SSH_URL is not configured and publish directly" do
    article = create(:article, :publishing)
    user = create(:user)

    # With no ENV vars set, should still transition to published
    PublishArticleJob.perform_now(article, user)

    article.reload
    assert_equal "published", article.status
  end

  should "not publish an article that is in draft state" do
    article = create(:article, :draft)
    user = create(:user)

    PublishArticleJob.perform_now(article, user)

    article.reload
    assert_equal "draft", article.status
  end

  should "not publish an article that is already published" do
    article = create(:article, :published)
    user = create(:user)
    original_published_at = article.published_at

    PublishArticleJob.perform_now(article, user)

    article.reload
    assert_equal "published", article.status
    assert_equal original_published_at.to_i, article.published_at.to_i
  end

  should "work without a user argument" do
    article = create(:article, :publishing)

    PublishArticleJob.perform_now(article)

    article.reload
    assert_equal "published", article.status
  end
end
