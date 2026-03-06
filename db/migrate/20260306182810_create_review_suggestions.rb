class CreateReviewSuggestions < ActiveRecord::Migration[8.1]
  def change
    create_table :review_suggestions do |t|
      t.references :article_review, null: false, foreign_key: true
      t.string :process, null: false
      t.string :category, null: false
      t.text :original_text
      t.text :suggested_text, null: false
      t.text :explanation, null: false
      t.string :status, null: false, default: "pending"

      t.timestamps
    end
  end
end
