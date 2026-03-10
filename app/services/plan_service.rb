# frozen_string_literal: true

class PlanService
  PLAN_RESPONSE_SCHEMA = {
    type: "object",
    properties: {
      plan: { type: "string" }
    },
    required: %w[plan]
  }.freeze

  BASE_PLAN_PROMPT = <<~PROMPT.freeze
    The plan should include:
    - A clear outline with sections and subsections (using markdown headings)
    - Key points to cover in each section
    - Suggested flow and transitions between sections

    %{context}

    Article title: %{title}
    Article body:
    %{body}
  PROMPT

  def initialize(user)
    @setting = Setting.for(user)
  end

  def generate_plan(article)
    context = if article.plan.present?
      "The article already has a plan. Improve and refine it:\n#{article.plan}"
    else
      "No existing plan. Create one from scratch."
    end

    prompt = format(@setting.plan_prompt + BASE_PLAN_PROMPT, context: context, title: article.title, body: article.body)
    response = call_llm(prompt)
    parsed = JSON.parse(response.to_s)
    parsed["plan"]
  rescue JSON::ParserError => e
    Rails.logger.error("PlanService JSON parse error: #{e.message}")
    nil
  end

  def call_llm(prompt)
    llm = LangchainClient.for_user(@setting.user)

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
