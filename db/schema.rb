# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_05_31_161953) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "game_memberships", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "game_id", null: false
    t.string "role"
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["game_id"], name: "index_game_memberships_on_game_id"
    t.index ["user_id", "game_id"], name: "index_game_memberships_on_user_id_and_game_id", unique: true
    t.index ["user_id"], name: "index_game_memberships_on_user_id"
  end

  create_table "games", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "archived_at"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "system"
    t.string "title", null: false
    t.datetime "updated_at", null: false
  end

  create_table "resource_templates", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "archived_at"
    t.string "creatable_by", default: "gm", null: false
    t.datetime "created_at", null: false
    t.uuid "game_id", null: false
    t.string "name", null: false
    t.jsonb "schema", default: {}, null: false
    t.string "template_type", null: false
    t.datetime "updated_at", null: false
    t.index ["game_id", "name"], name: "index_resource_templates_on_game_id_and_name", unique: true
    t.index ["game_id"], name: "index_resource_templates_on_game_id"
    t.index ["template_type"], name: "index_resource_templates_on_template_type"
  end

  create_table "resources", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "archived_at"
    t.datetime "created_at", null: false
    t.jsonb "data", default: {}, null: false
    t.uuid "game_id", null: false
    t.string "name"
    t.uuid "player_id"
    t.uuid "resource_template_id", null: false
    t.datetime "updated_at", null: false
    t.index ["game_id", "player_id"], name: "index_resources_on_game_id_and_player_id"
    t.index ["game_id", "resource_template_id"], name: "index_resources_on_game_id_and_resource_template_id"
    t.index ["game_id"], name: "index_resources_on_game_id"
    t.index ["player_id"], name: "index_resources_on_player_id"
    t.index ["resource_template_id"], name: "index_resources_on_resource_template_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "encrypted_password", null: false
    t.string "jti", null: false
    t.datetime "updated_at", null: false
    t.string "username", null: false
    t.index ["jti"], name: "index_users_on_jti", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "game_memberships", "games"
  add_foreign_key "game_memberships", "users"
  add_foreign_key "resource_templates", "games"
  add_foreign_key "resources", "games"
  add_foreign_key "resources", "resource_templates"
  add_foreign_key "resources", "users", column: "player_id"
end
