FactoryBot.define do
  factory :user do
    email_address { "admin@kupo.com" }
    password { "password123" }
  end
end
