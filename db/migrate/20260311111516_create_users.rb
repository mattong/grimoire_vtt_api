class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users, id: :uuid do |t|
      t.string :username, null: false

      t.string :encrypted_password, null: false

      t.string :jti, null: false

      t.timestamps
    end

    add_index :users, :username, unique: true
    add_index :users, :jti, unique: true
  end
end
