# frozen_string_literal: true

class PlanService
  PLAN_PROMPT = <<~PROMPT
    You are an expert content strategist and article planner. Based on the article title, current content, and any existing plan, generate a structured article plan in markdown.

    The plan should include:
    - A clear outline with sections and subsections (using markdown headings)
    - Key points to cover in each section
    - Suggested flow and transitions between sections

    %{context}

    Article title: %{title}
    Article body:
    %{body}
  PROMPT

  PLAN_RESPONSE_SCHEMA = {
    type: "object",
    properties: {
      plan: { type: "string" }
    },
    required: %w[plan]
  }.freeze

  def generate_plan(article)
    context = if article.plan.present?
      "The article already has a plan. Improve and refine it:\n#{article.plan}"
    else
      "No existing plan. Create one from scratch."
    end

    prompt = format(PLAN_PROMPT, context: context, title: article.title, body: article.body)
    response = call_llm(prompt)
    parsed = JSON.parse(response.to_s)
    parsed["plan"]
  rescue JSON::ParserError => e
    Rails.logger.error("PlanService JSON parse error: #{e.message}")
    nil
  end

  def call_llm(prompt)
    llm = Langchain::LLM::GoogleGemini.new(
      api_key: ENV.fetch("GEMINI_API_KEY"),
      default_options: { chat_model: "gemini-2.5-flash" }
    )

    response = llm.chat(
      messages: [ { role: "user", parts: [ { text: prompt } ] } ],
      response_format: "application/json",
      generation_config: {
        response_schema: PLAN_RESPONSE_SCHEMA
      }
    )

    response.chat_completion
  end
end
