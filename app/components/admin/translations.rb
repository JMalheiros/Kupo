# frozen_string_literal: true

class Components::Admin::Translations < Components::Base
  def initialize(article:)
    @article = article
    @translations = ArticleTranslation::LANGUAGES.keys.index_with { |lang|
      @article.article_translations.find_by(language: lang)
    }
  end

  def view_template
    div(id: "article-translation-editor") do
      if @article.persisted?
        tag(:"turbo-cable-stream-source",
          channel: "Turbo::StreamsChannel",
          "signed-stream-name": Turbo::StreamsChannel.signed_stream_name(Current.user)
        )
      end

      div(class: "space-y-6 py-4") do
        Tabs(default: ArticleTranslation::LANGUAGES.keys.first) do
          TabsList do
            ArticleTranslation::LANGUAGES.each do |code, name|
              TabsTrigger(value: code) { name }
            end
          end

          ArticleTranslation::LANGUAGES.each do |code, name|
            TabsContent(value: code) do
              language_panel(code, name, @translations[code])
            end
          end
        end
      end
    end
  end

  private

  def language_panel(language, language_name, translation)
    render Components::Admin::Translations::LanguagePanel.new(
      article: @article,
      language: language,
      language_name: language_name,
      translation: translation
    )
  end
end
