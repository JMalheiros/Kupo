# frozen_string_literal: true

class ApiKey < ApplicationRecord
  PROVIDERS = %w[gemini claude openai ollama].freeze

  belongs_to :user

  encrypts :api_key

  validates :provider, presence: true, inclusion: { in: PROVIDERS }
  validates :provider, uniqueness: { scope: :user_id }
  validates :api_key, presence: true, unless: :ollama?
  validates :url, presence: true, if: :ollama?

  def ollama?
    provider == "ollama"
  end
end
