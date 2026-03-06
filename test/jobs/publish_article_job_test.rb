# frozen_string_literal: true

require "test_helper"

class PublishArticleJobTest < ActiveSupport::TestCase
  should "publish a publishing article when Hugo is configured" do
    article = create(:article, :publishing)
    user = create(:user)

    with_stubbed_hugo_publisher do
      PublishArticleJob.perform_now(article, user)
    end

    article.reload
    assert_equal "published", article.status
  end

  should "publish a scheduled article by transitioning through publishing to published" do
    article = create(:article, :scheduled, published_at: 1.minute.ago)
    user = create(:user)

    with_stubbed_hugo_publisher do
      PublishArticleJob.perform_now(article, user)
    end

    article.reload
    assert_equal "published", article.status
  end

  should "revert to draft when Hugo is not configured" do
    article = create(:article, :publishing)
    user = create(:user)

    PublishArticleJob.perform_now(article, user)

    article.reload
    assert_equal "draft", article.status
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

  should "revert to draft without a user argument when Hugo is not configured" do
    article = create(:article, :publishing)

    PublishArticleJob.perform_now(article)

    article.reload
    assert_equal "draft", article.status
  end

  private

  def with_stubbed_hugo_publisher
    original_new = HugoPublisher.method(:new)
    stub_publisher = Class.new do
      define_method(:call) { true }
    end

    HugoPublisher.define_singleton_method(:new) { |*_args| stub_publisher.new }
    yield
  ensure
    HugoPublisher.define_singleton_method(:new, original_new)
  end
end
