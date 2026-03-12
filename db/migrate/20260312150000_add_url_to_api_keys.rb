# frozen_string_literal: true

class AddUrlToApiKeys < ActiveRecord::Migration[8.1]
  def change
    add_column :api_keys, :url, :string
    change_column_null :api_keys, :api_key, true
  end
end
