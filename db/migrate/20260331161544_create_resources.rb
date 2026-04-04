class CreateResources < ActiveRecord::Migration[8.1]
  def change
    create_table :resources, id: :uuid do |t|
      t.references :resource_template, null: false, foreign_key: true, type: :uuid
      t.references :game, null: false, foreign_key: true, type: :uuid
      t.string :name
      t.jsonb :data, null: false, default: {}
      t.references :player, foreign_key: { to_table: :users }, type: :uuid
      t.datetime :archived_at

      t.timestamps
    end

    add_index :resources, [:game_id, :resource_template_id]
    add_index :resources, [:game_id, :player_id]
  end
end
