class Article < ApplicationRecord
  has_many :article_categories, dependent: :destroy
  has_many :categories, through: :article_categories
  has_many_attached :images
  has_many :article_reviews, dependent: :destroy

  validates :title, presence: true
  validates :body, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :status, presence: true, inclusion: { in: %w[draft scheduled publishing published] }

  before_validation :generate_slug, if: -> { slug.blank? }

  scope :published, -> { where(status: "published") }
  scope :drafts, -> { where(status: "draft") }
  scope :scheduled, -> { where(status: "scheduled") }
  scope :recent, -> { order(published_at: :desc) }

  def publish_now!
    update!(status: "publishing", published_at: Time.current)
    PublishArticleJob.perform_later(self, Current.user)
  end

  def schedule!(time)
    update!(status: "scheduled", published_at: time)
    PublishArticleJob.set(wait_until: time).perform_later(self, Current.user)
  end

  private

  def generate_slug
    base_slug = title&.parameterize
    if Article.exists?(slug: base_slug)
      self.slug = "#{base_slug}-#{SecureRandom.hex(4)}"
    else
      self.slug = base_slug
    end
  end
end
