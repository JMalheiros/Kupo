FactoryBot.define do
  factory :article_review do
    article
    content_status { "pending" }
    seo_status { "pending" }
  end
end
