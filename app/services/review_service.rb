class ReviewService
  CONTENT_PROMPT = <<~PROMPT
    You are an expert editor. Review the following article and provide suggestions for improvements.
    Focus on: grammar, clarity, tone, and structure.

    For each suggestion, provide:
    - "category": one of "grammar", "clarity", "tone", "structure"
    - "original_text": the exact text from the article that needs improvement (copy it exactly)
    - "suggested_text": your suggested replacement
    - "explanation": brief explanation of why this change improves the article

    Article title: %{title}
    Article body:
    %{body}
  PROMPT

  SEO_PROMPT = <<~PROMPT
    You are an SEO and content strategy expert. Review the following article and provide suggestions.
    Focus on: title improvements, SEO optimization, summary/excerpt, and tags/categories.

    For each suggestion, provide:
    - "category": one of "title", "seo", "summary", "tags"
    - "original_text": the current text being improved (or empty string for new additions like tags)
    - "suggested_text": your suggested improvement or addition
    - "explanation": brief explanation of why this improves the article's reach

    Article title: %{title}
    Article body:
    %{body}
  PROMPT

  RESPONSE_SCHEMA = {
    type: "object",
    properties: {
      suggestions: {
        type: "array",
        items: {
          type: "object",
          properties: {
            category: { type: "string" },
            original_text: { type: "string" },
            suggested_text: { type: "string" },
            explanation: { type: "string" }
          },
          required: %w[category original_text suggested_text explanation]
        }
      }
    },
    required: %w[suggestions]
  }.freeze

  def content_review(article)
    prompt = format(CONTENT_PROMPT, title: article.title, body: article.body)
    parse_response(call_llm(prompt, RESPONSE_SCHEMA))
  end

  def seo_review(article)
    prompt = format(SEO_PROMPT, title: article.title, body: article.body)
    parse_response(call_llm(prompt, RESPONSE_SCHEMA))
  end

  def call_llm(prompt, response_schema)
    llm = Langchain::LLM::GoogleGemini.new(
      api_key: ENV.fetch("GEMINI_API_KEY"),
      default_options: { chat_model: "gemini-2.5-flash" }
    )

    response = llm.chat(
      messages: [ { role: "user", parts: [ { text: prompt } ] } ],
      response_format: "application/json",
      generation_config: {
        response_schema: response_schema
      }
    )

    response.chat_completion
  end

  private

  def parse_response(response_text)
    parsed = JSON.parse(response_text.to_s)
    suggestions = parsed["suggestions"]
    return [] unless suggestions.is_a?(Array)

    suggestions.map do |s|
      {
        category: s["category"],
        original_text: s["original_text"],
        suggested_text: s["suggested_text"],
        explanation: s["explanation"]
      }
    end
  rescue JSON::ParserError => e
    Rails.logger.error("ReviewService JSON parse error: #{e.message}")
    []
  end
end
