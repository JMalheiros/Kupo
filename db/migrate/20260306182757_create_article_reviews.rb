class CreateArticleReviews < ActiveRecord::Migration[8.1]
  def change
    create_table :article_reviews do |t|
      t.references :article, null: false, foreign_key: true
      t.string :content_status, null: false, default: "pending"
      t.string :seo_status, null: false, default: "pending"

      t.timestamps
    end
  end
end
