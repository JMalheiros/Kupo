class CreateSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :settings do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.text :plan_prompt, null: false
      t.text :content_review_prompt, null: false
      t.text :seo_review_prompt, null: false
      t.string :llm_provider, null: false, default: "gemini"
      t.string :llm_model, null: false, default: "gemini-3-flash"

      t.timestamps
    end
  end
end
