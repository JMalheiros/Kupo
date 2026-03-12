# frozen_string_literal: true

class Components::Admin::Translations::LanguagePanel < Components::Base
  def initialize(article:, language:, language_name:, translation:)
    @article = article
    @language = language
    @language_name = language_name
    @translation = translation
  end

  def view_template
    div(class: "space-y-4 pt-4") do
      render Components::Admin::Translations::TranslateButton.new(
        article: @article,
        language: @language,
        language_name: @language_name,
        translation: @translation
      )
      translation_content
    end
  end

  private

  def translation_content
    return unless @translation

    case @translation.status
    when "pending"
      div(class: "flex items-center justify-center gap-2") do
        Text(size: "sm", weight: "muted", class: "animate-pulse") { "Translating..." }
      end
    when "failed"
      Alert(variant: :destructive) do
        AlertTitle { "Translation failed" }
        AlertDescription { "Please try again." }
      end
    when "completed"
      render Components::Admin::Translations::CompletedTranslation.new(
        article: @article,
        language: @language,
        translation: @translation
      )
    end
  end
end
