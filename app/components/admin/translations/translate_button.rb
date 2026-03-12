# frozen_string_literal: true

class Components::Admin::Translations::TranslateButton < Components::Base
  def initialize(article:, language:, language_name:, translation:)
    @article = article
    @language = language
    @language_name = language_name
    @translation = translation
  end

  def view_template
    div(class: "flex justify-center") do
      Form(action: translate_article_path(slug: @article.slug), method: "post") do
        Input(type: :hidden, name: "authenticity_token", value: form_authenticity_token)
        Input(type: :hidden, name: "language", value: @language)
        Button(type: :submit, disabled: @translation&.status == "pending") do
          Lucide::Sparkles(variant: :filled, class: "h-4 w-4 mr-1.5 inline-block")
          plain button_label
        end
      end
    end
  end

  private

  def button_label
    if @translation&.status == "pending"
      "Translating..."
    elsif @translation&.status == "completed"
      "Re-translate"
    else
      "Translate to #{@language_name}"
    end
  end
end
