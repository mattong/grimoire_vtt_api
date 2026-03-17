class CreateGameMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :game_memberships do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :game, null: false, foreign_key: true, type: :uuid
      t.string :role

      t.timestamps
    end
  end
end
