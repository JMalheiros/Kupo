class PublishArticleJob < ApplicationJob
  queue_as :default

  def perform(article)
    return unless article.status == "scheduled"
    article.publish_now!
  end
end
