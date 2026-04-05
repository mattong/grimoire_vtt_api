class CreateResourceTemplates < ActiveRecord::Migration[8.1]
  def change
    create_table :resource_templates, id: :uuid do |t|
      t.references :game, null: false, foreign_key: true, type: :uuid
      t.string :name, null: false
      t.string :template_type, null: false
      t.jsonb :schema, null: false, default: {}
      t.datetime :archived_at

      t.timestamps
    end

    add_index :resource_templates, [:game_id, :name], unique: true
    add_index :resource_templates, :template_type
  end
end
