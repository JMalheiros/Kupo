# frozen_string_literal: true

class Components::Admin::Translations::TranslateButton < Components::Base
  def initialize(article:, language:, language_name:, translation:)
    @article = article
    @language = language
    @language_name = language_name
    @translation = translation
  end

  def view_template
    div(class: "flex items-center justify-center gap-3") do
      if @translation&.status == "pending"
        p(class: "text-sm text-muted-foreground animate-pulse") { "Translating to #{@language_name}..." }
        Button(disabled: true) do
          Lucide::LoaderCircle(class: "h-4 w-4 mr-1.5 inline-block animate-spin")
          plain "Translate to #{@language_name}"
        end
      else
        Form(action: translate_article_path(slug: @article.slug), method: "post") do
          Input(type: :hidden, name: "authenticity_token", value: form_authenticity_token)
          Input(type: :hidden, name: "language", value: @language)
          Button(type: :submit) do
            Lucide::Sparkles(variant: :filled, class: "h-4 w-4 mr-1.5 inline-block")
            plain @translation&.status == "completed" ? "Re-translate" : "Translate to #{@language_name}"
          end
        end
      end
    end
  end
end
