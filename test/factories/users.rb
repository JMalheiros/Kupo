FactoryBot.define do
  factory :user do
    sequence(:email_address) { |n| "admin#{n}@kupo.com" }
    password { "password123" }
  end
end
