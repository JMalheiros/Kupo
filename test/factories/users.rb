FactoryBot.define do
  factory :user do
    email_address { "admin@mstation.com" }
    password { "password123" }
  end
end
