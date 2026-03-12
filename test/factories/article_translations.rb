FactoryBot.define do
  factory :article_translation do
    article
    language { "en" }
    status { "pending" }

    trait :completed do
      status { "completed" }
      title { "Translated Title" }
      body { "# Translated Body\n\nThis is the translated content." }
    end

    trait :failed do
      status { "failed" }
    end

    trait :portuguese do
      language { "pt-BR" }
    end
  end
end
