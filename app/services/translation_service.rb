# frozen_string_literal: true

class TranslationService
  TRANSLATION_RESPONSE_SCHEMA = {
    type: "object",
    properties: {
      title: { type: "string" },
      body: { type: "string" }
    },
    required: %w[title body]
  }.freeze

  BASE_TRANSLATION_PROMPT = <<~PROMPT.freeze
    Translate the article title and body to %{language_name}.
    Preserve all markdown formatting exactly as-is.
    Return a JSON object with "title" and "body" keys.

    Article title: %{title}
    Article body:
    %{body}
  PROMPT

  def initialize(user)
    @setting = Setting.for(user)
  end

  def translate(article, language:)
    language_name = ArticleTranslation::LANGUAGES.fetch(language)
    prompt = format(
      @setting.translation_prompt + "\n\n" + BASE_TRANSLATION_PROMPT,
      language_name: language_name,
      title: article.title,
      body: article.body
    )
    response = call_llm(prompt)
    parsed = JSON.parse(response.to_s)
    return nil unless parsed["title"].present? && parsed["body"].present?
    parsed
  rescue JSON::ParserError => e
    Rails.logger.error("TranslationService JSON parse error: #{e.message}")
    nil
  end

  def call_llm(prompt)
    llm = LangchainClient.for_user(@setting.user)

    response = llm.chat(
      messages: [ { role: "user", parts: [ { text: prompt } ] } ],
      response_format: "application/json",
      generation_config: {
        response_schema: TRANSLATION_RESPONSE_SCHEMA
      }
    )

    response.chat_completion
  end
end
