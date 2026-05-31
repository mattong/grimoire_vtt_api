class AddSlugsAndGmIdToGames < ActiveRecord::Migration[8.1]
  disable_ddl_transaction! if respond_to?(:disable_ddl_transaction!)

  def up
    # Add slug columns
    add_column :games, :slug, :string
    add_column :resource_templates, :slug, :string
    add_column :resources, :slug, :string

    # Add gm_id (nullable first for backfill)
    add_column :games, :gm_id, :uuid
    add_foreign_key :games, :users, column: :gm_id

    # Backfill gm_id from game_memberships
    Game.reset_column_information
    Game.find_each do |game|
      gm_membership = game.game_memberships.find_by(role: :gm)
      if gm_membership
        game.update_column(:gm_id, gm_membership.user_id)
      end
    end

    # Now add the NOT NULL constraint
    change_column_null :games, :gm_id, false

    # Add composite unique indexes
    add_index :games, [:gm_id, :slug], unique: true, where: "slug IS NOT NULL"
    add_index :resource_templates, [:game_id, :slug], unique: true, where: "slug IS NOT NULL"
    add_index :resources, [:game_id, :slug], unique: true, where: "slug IS NOT NULL"
  end

  def down
    remove_index :games, [:gm_id, :slug]
    remove_index :resource_templates, [:game_id, :slug]
    remove_index :resources, [:game_id, :slug]
    remove_column :games, :gm_id
    remove_column :games, :slug
    remove_column :resource_templates, :slug
    remove_column :resources, :slug
  end
end
