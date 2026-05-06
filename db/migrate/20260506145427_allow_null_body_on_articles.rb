class AllowNullBodyOnArticles < ActiveRecord::Migration[8.1]
  def change
    change_column_null :articles, :body, true
  end
end
