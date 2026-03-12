class CreateArticleTranslations < ActiveRecord::Migration[8.1]
  def change
    create_table :article_translations do |t|
      t.references :article, null: false, foreign_key: true
      t.string :language, null: false, default: "en"
      t.text :title
      t.text :body
      t.string :status, null: false, default: "pending"

      t.timestamps
    end

    add_index :article_translations, [ :article_id, :language ], unique: true
  end
end
