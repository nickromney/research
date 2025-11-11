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

ActiveRecord::Schema[8.1].define(version: 2024_01_20_000006) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "projects", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.bigint "owner_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_group_id"
    t.index ["owner_id"], name: "index_projects_on_owner_id"
    t.index ["user_group_id"], name: "index_projects_on_user_group_id"
  end

  create_table "renewals", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "last_executed_at"
    t.text "last_output"
    t.string "name", null: false
    t.datetime "next_execution_at"
    t.string "renewal_type", null: false
    t.string "schedule"
    t.text "script"
    t.bigint "server_id", null: false
    t.string "status", default: "pending"
    t.datetime "updated_at", null: false
    t.index ["server_id"], name: "index_renewals_on_server_id"
  end

  create_table "servers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "hostname", null: false
    t.datetime "last_checked_at"
    t.string "name", null: false
    t.integer "port", default: 22
    t.bigint "project_id", null: false
    t.text "ssh_key"
    t.string "ssh_key_path"
    t.string "status", default: "unknown"
    t.datetime "updated_at", null: false
    t.string "username"
    t.index ["project_id"], name: "index_servers_on_project_id"
  end

  create_table "services", force: :cascade do |t|
    t.string "check_command"
    t.datetime "created_at", null: false
    t.datetime "last_checked_at"
    t.string "name", null: false
    t.bigint "server_id", null: false
    t.string "service_type", null: false
    t.string "status", default: "unknown"
    t.text "status_output"
    t.datetime "updated_at", null: false
    t.index ["server_id"], name: "index_services_on_server_id"
  end

  create_table "user_group_memberships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "role", default: "member"
    t.datetime "updated_at", null: false
    t.bigint "user_group_id", null: false
    t.bigint "user_id", null: false
    t.index ["user_group_id"], name: "index_user_group_memberships_on_user_group_id"
    t.index ["user_id", "user_group_id"], name: "index_user_group_memberships_unique", unique: true
    t.index ["user_id"], name: "index_user_group_memberships_on_user_id"
  end

  create_table "user_groups", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "name"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "role", default: "user"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "projects", "user_groups"
  add_foreign_key "projects", "users", column: "owner_id"
  add_foreign_key "renewals", "servers"
  add_foreign_key "servers", "projects"
  add_foreign_key "services", "servers"
  add_foreign_key "user_group_memberships", "user_groups"
  add_foreign_key "user_group_memberships", "users"
end
