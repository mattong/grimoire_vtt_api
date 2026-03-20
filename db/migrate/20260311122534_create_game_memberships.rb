class CreateGameMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :game_memberships, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :game, null: false, foreign_key: true, type: :uuid
      t.string :role

      t.timestamps
    end

    add_index :game_memberships, [ :user_id, :game_id ], unique: true
  end
end
