FactoryBot.define do
  factory :api_key do
    user
    provider { "gemini" }
    api_key { "test-api-key-123" }
  end
end
