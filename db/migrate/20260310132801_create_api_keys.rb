class CreateApiKeys < ActiveRecord::Migration[8.1]
  def change
    create_table :api_keys do |t|
      t.references :user, null: false, foreign_key: true
      t.string :provider, null: false
      t.string :api_key, null: false

      t.timestamps
    end

    add_index :api_keys, [ :user_id, :provider ], unique: true
  end
end
