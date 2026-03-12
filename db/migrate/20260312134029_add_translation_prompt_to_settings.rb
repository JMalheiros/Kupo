class AddTranslationPromptToSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :settings, :translation_prompt, :text, null: false, default: "You are a professional translator. Translate the following article accurately and naturally."
  end
end
