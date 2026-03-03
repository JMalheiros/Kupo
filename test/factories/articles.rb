FactoryBot.define do
  factory :article do
    sequence(:title) { |n| "Article Title #{n}" }
    sequence(:slug) { |n| "article-title-#{n}" }
    body { "# Hello World\n\nThis is a **markdown** article." }
    status { "draft" }

    trait :draft do
      status { "draft" }
      published_at { nil }
    end

    trait :scheduled do
      status { "scheduled" }
      published_at { 1.day.from_now }
    end

    trait :published do
      status { "published" }
      published_at { 1.hour.ago }
    end
  end
end
