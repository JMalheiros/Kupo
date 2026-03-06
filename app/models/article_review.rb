class ArticleReview < ApplicationRecord
  belongs_to :article
  has_many :review_suggestions, dependent: :destroy

  validates :content_status, presence: true, inclusion: { in: %w[pending completed failed] }
  validates :seo_status, presence: true, inclusion: { in: %w[pending completed failed] }
end
