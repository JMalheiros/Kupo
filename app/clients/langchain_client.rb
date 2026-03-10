# frozen_string_literal: true

class LangchainClient
  PROVIDERS = {
    "gemini" => {
      class: Langchain::LLM::GoogleGemini,
      env_key: "GEMINI_API_KEY",
      default_model: "gemini-2.5-flash"
    },
    "claude" => {
      class: Langchain::LLM::Anthropic,
      env_key: "ANTHROPIC_API_KEY",
      default_model: "claude-sonnet-4-20250514"
    },
    "openai" => {
      class: Langchain::LLM::OpenAI,
      env_key: "OPENAI_API_KEY",
      default_model: "gpt-4o-mini"
    }
  }.freeze

  class << self
    def for_user(user)
      setting = Setting.for(user)
      build(setting.llm_provider, model: setting.llm_model, user: user)
    end

    def gemini(model: nil)
      build("gemini", model: model)
    end

    def claude(model: nil)
      build("claude", model: model)
    end

    def openai(model: nil)
      build("openai", model: model)
    end

    private

    def build(provider, model: nil, user: nil)
      config = PROVIDERS.fetch(provider)
      model ||= config[:default_model]
      api_key = resolve_api_key(provider, config[:env_key], user)

      config[:class].new(
        api_key: api_key,
        default_options: { chat_model: model }
      )
    end

    def resolve_api_key(provider, env_key, user)
      if user
        user.api_keys.find_by(provider: provider)&.api_key || ENV.fetch(env_key)
      else
        ENV.fetch(env_key)
      end
    end
  end
end
