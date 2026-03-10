# frozen_string_literal: true

class Setting < ApplicationRecord
  DEFAULT_PLAN_PROMPT = <<~PROMPT.freeze
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

  DEFAULT_CONTENT_REVIEW_PROMPT = <<~PROMPT.freeze
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

  DEFAULT_SEO_REVIEW_PROMPT = <<~PROMPT.freeze
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

  belongs_to :user

  validates :llm_provider, presence: true, inclusion: { in: %w[gemini claude openai] }
  validates :llm_model, presence: true

  def self.for(user)
    user.setting || user.create_setting!(
      plan_prompt: DEFAULT_PLAN_PROMPT,
      content_review_prompt: DEFAULT_CONTENT_REVIEW_PROMPT,
      seo_review_prompt: DEFAULT_SEO_REVIEW_PROMPT,
      llm_provider: "gemini",
      llm_model: "gemini-2.5-flash"
    )
  end

  def self.for_edit(user)
    setting = self.for(user)
    build_missing_api_keys(user)
    setting
  end

  def self.build_missing_api_keys(user)
    existing = user.api_keys.pluck(:provider)
    (ApiKey::PROVIDERS - existing).each do |provider|
      user.api_keys.build(provider: provider)
    end
  end
end
