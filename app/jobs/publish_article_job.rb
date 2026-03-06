# frozen_string_literal: true

class PublishArticleJob < ApplicationJob
  queue_as :default

  def perform(article, user = nil)
    case article.status
    when "scheduled"
      article.update!(status: "publishing", published_at: Time.current)
      HugoPublisher.new(article).call
      article.update!(status: "published")
    when "publishing"
      HugoPublisher.new(article).call
      article.update!(status: "published")
    end
  rescue => e
    Rails.logger.error("Hugo publish failed for #{article.slug}: #{e.class} - #{e.message}")
    article.update!(status: "draft")
  end
end
