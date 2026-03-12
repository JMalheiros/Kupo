# frozen_string_literal: true

class TranslateArticleJob < ApplicationJob
  queue_as :default

  def perform(article, user, language)
    translation = article.article_translations.find_or_initialize_by(language: language)
    translation.update!(status: "pending")

    result = TranslationService.new(user).translate(article, language: language)

    if result.present?
      translation.update!(title: result["title"], body: result["body"], status: "completed")
      broadcast_translation(translation, user)
    else
      translation.update!(status: "failed")
      broadcast_error(user)
    end
  rescue => e
    Rails.logger.error("TranslateArticleJob failed: #{e.class} - #{e.message}")
    translation = article.article_translations.find_or_initialize_by(language: language)
    translation.update!(status: "failed")
    broadcast_error(user)
  end

  private

  def broadcast_translation(translation, user)
    html = ApplicationController.render(
      Components::Admin::Translations.new(article: translation.article),
      layout: false
    )

    Turbo::StreamsChannel.broadcast_replace_to(
      user,
      target: "article-translation-editor",
      html: html
    )
  end

  def broadcast_error(user)
    Turbo::StreamsChannel.broadcast_replace_to(
      user,
      target: "article-translation-editor",
      html: "<p id='article-translation-editor' class='text-sm text-destructive'>Translation failed. Please try again.</p>"
    )
  end
end
