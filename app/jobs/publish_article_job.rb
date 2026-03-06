# frozen_string_literal: true

class PublishArticleJob < ApplicationJob
  queue_as :default

  def perform(article, user = nil)
    case article.status
    when "scheduled"
      article.update!(status: "publishing", published_at: Time.current)
      HugoPublisher.new(article).call
      article.update!(status: "published")
      broadcast_toast(user, :success, "'#{article.title}' published successfully")
    when "publishing"
      HugoPublisher.new(article).call
      article.update!(status: "published")
      broadcast_toast(user, :success, "'#{article.title}' published successfully")
    end
  rescue => e
    Rails.logger.error("Hugo publish failed for #{article.slug}: #{e.message}")
    article.update!(status: "draft")
    broadcast_toast(user, :destructive, "Failed to publish '#{article.title}'")
  end

  private

  def broadcast_toast(user, variant, message)
    return unless user

    html = ApplicationController.render(
      partial: "shared/toast",
      locals: { variant: variant, message: message }
    )

    Turbo::StreamsChannel.broadcast_append_to(
      user,
      target: "notifications",
      html: html
    )
  end
end
