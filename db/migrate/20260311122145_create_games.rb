class CreateGames < ActiveRecord::Migration[8.1]
  def change
    create_table :games, id: :uuid do |t|
      t.string :title
      t.text :description
      t.string :system
      t.datetime :archived_at

      t.timestamps
    end
  end
end
