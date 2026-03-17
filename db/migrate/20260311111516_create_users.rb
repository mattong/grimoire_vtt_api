class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users, id: :uuid do |t|
      t.string :email
      t.string :username
      t.string :password_digest

      t.timestamps
    end
    add_index :users, :email
    add_index :users, :username
  end
end
