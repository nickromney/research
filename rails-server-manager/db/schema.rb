# This file is auto-generated from the current state of the database.

ActiveRecord::Schema[9.0].define(version: 2024_01_20_000006) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "name"
    t.string "role", default: "user"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "user_groups", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "user_group_memberships", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "user_group_id", null: false
    t.string "role", default: "member"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "user_group_id"], name: "index_user_group_memberships_unique", unique: true
    t.index ["user_id"], name: "index_user_group_memberships_on_user_id"
    t.index ["user_group_id"], name: "index_user_group_memberships_on_user_group_id"
  end

  create_table "projects", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.bigint "user_group_id"
    t.bigint "owner_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_id"], name: "index_projects_on_owner_id"
    t.index ["user_group_id"], name: "index_projects_on_user_group_id"
  end

  create_table "servers", force: :cascade do |t|
    t.string "name", null: false
    t.string "hostname", null: false
    t.integer "port", default: 22
    t.string "username"
    t.text "ssh_key"
    t.string "ssh_key_path"
    t.text "description"
    t.string "status", default: "unknown"
    t.datetime "last_checked_at"
    t.bigint "project_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_servers_on_project_id"
  end

  create_table "services", force: :cascade do |t|
    t.string "name", null: false
    t.string "service_type", null: false
    t.string "check_command"
    t.string "status", default: "unknown"
    t.text "status_output"
    t.datetime "last_checked_at"
    t.bigint "server_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["server_id"], name: "index_services_on_server_id"
  end

  create_table "renewals", force: :cascade do |t|
    t.string "name", null: false
    t.string "renewal_type", null: false
    t.text "script"
    t.text "description"
    t.datetime "last_executed_at"
    t.datetime "next_execution_at"
    t.string "schedule"
    t.string "status", default: "pending"
    t.text "last_output"
    t.bigint "server_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["server_id"], name: "index_renewals_on_server_id"
  end

  add_foreign_key "user_group_memberships", "user_groups"
  add_foreign_key "user_group_memberships", "users"
  add_foreign_key "projects", "users", column: "owner_id"
  add_foreign_key "projects", "user_groups"
  add_foreign_key "servers", "projects"
  add_foreign_key "services", "servers"
  add_foreign_key "renewals", "servers"
end
