class ReviewSuggestion < ApplicationRecord
  belongs_to :article_review

  validates :process, presence: true, inclusion: { in: %w[content seo] }
  validates :category, presence: true, inclusion: { in: %w[grammar clarity tone structure title seo summary tags] }
  validates :suggested_text, presence: true
  validates :explanation, presence: true
  validates :status, presence: true, inclusion: { in: %w[pending accepted rejected] }
end
