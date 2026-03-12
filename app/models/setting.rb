# frozen_string_literal: true

class Setting < ApplicationRecord
  DEFAULT_PLAN_PROMPT = <<~PROMPT.freeze
    You are an expert content strategist and article planner. Based on the article title, current content, and any existing plan, generate a structured article plan in markdown.
  PROMPT

  DEFAULT_CONTENT_REVIEW_PROMPT = <<~PROMPT.freeze
    You are an expert editor. Review the following article and provide suggestions for improvements.
  PROMPT

  DEFAULT_SEO_REVIEW_PROMPT = <<~PROMPT.freeze
    You are an SEO and content strategy expert. Review the following article and provide suggestions.
  PROMPT

  DEFAULT_TRANSLATION_PROMPT = <<~PROMPT.freeze
    You are a professional translator. Translate the following article accurately and naturally, preserving all markdown formatting.
  PROMPT

  belongs_to :user

  validates :llm_provider, presence: true, inclusion: { in: %w[gemini claude openai ollama] }
  validates :llm_model, presence: true

  def self.for(user)
    user.setting || user.create_setting!(
      plan_prompt: DEFAULT_PLAN_PROMPT,
      content_review_prompt: DEFAULT_CONTENT_REVIEW_PROMPT,
      seo_review_prompt: DEFAULT_SEO_REVIEW_PROMPT,
      translation_prompt: DEFAULT_TRANSLATION_PROMPT,
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
