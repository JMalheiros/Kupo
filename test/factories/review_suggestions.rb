FactoryBot.define do
  factory :review_suggestion do
    article_review
    process { "content" }
    category { "grammar" }
    original_text { "This is a orginal text." }
    suggested_text { "This is an original text." }
    explanation { "Fixed article: 'a' should be 'an' before a vowel." }
    status { "pending" }

    trait :seo do
      process { "seo" }
      category { "title" }
      original_text { "My Article" }
      suggested_text { "10 Tips for Writing Better Articles" }
      explanation { "More engaging and SEO-friendly title." }
    end

    trait :accepted do
      status { "accepted" }
    end

    trait :rejected do
      status { "rejected" }
    end
  end
end
