class AddPlanToArticles < ActiveRecord::Migration[8.1]
  def change
    add_column :articles, :plan, :text
  end
end
