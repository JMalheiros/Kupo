class ArticleTranslation < ApplicationRecord
  LANGUAGES = { "en" => "English", "pt-BR" => "Brazilian Portuguese" }.freeze

  belongs_to :article

  validates :language, presence: true, inclusion: { in: LANGUAGES.keys }
  validates :status, presence: true, inclusion: { in: %w[pending completed failed] }
end
