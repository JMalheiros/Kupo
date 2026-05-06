class RemovePlanPromptFromSettings < ActiveRecord::Migration[8.1]
  def change
    remove_column :settings, :plan_prompt, :text
  end
end
