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

ActiveRecord::Schema.define(version: 2026_08_19_154525) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_admin_comments", force: :cascade do |t|
    t.string "namespace"
    t.text "body"
    t.string "resource_type"
    t.bigint "resource_id"
    t.string "author_type"
    t.bigint "author_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource"
  end

  create_table "roles", force: :cascade do |t|
    t.string "name"
    t.string "code"
    t.text "description"
    t.boolean "active", default: true
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["code"], name: "index_roles_on_code", unique: true
    t.index ["name"], name: "index_roles_on_name", unique: true
  end

  create_table "transactions", force: :cascade do |t|
    t.string "request_id", null: false
    t.string "transaction_direction", default: "IN", null: false
    t.string "transaction_type", default: "UNKNOWN"
    t.decimal "transaction_amount", precision: 18, scale: 2, default: "0.0", null: false
    t.string "transaction_currency", default: "TZS", null: false
    t.date "transaction_date", null: false
    t.string "reference"
    t.text "narrative"
    t.string "bank_code"
    t.json "parties"
    t.json "raw_data"
    t.json "raw_fields"
    t.text "raw_message"
    t.string "status", default: "PENDING"
    t.string "screening_status", default: "NOT_SCREENED"
    t.json "screening_result"
    t.text "screening_error"
    t.datetime "screened_at"
    t.text "error_message"
    t.datetime "processed_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "rtgs_reference"
    t.text "raw_rtgs_message"
    t.jsonb "screening_attempts", default: []
    t.index ["reference"], name: "index_transactions_on_reference"
    t.index ["request_id"], name: "index_transactions_on_request_id", unique: true
    t.index ["rtgs_reference"], name: "index_transactions_on_rtgs_reference", unique: true, where: "(rtgs_reference IS NOT NULL)"
    t.index ["screening_status"], name: "index_transactions_on_screening_status"
    t.index ["status", "screening_status"], name: "index_transactions_on_status_and_screening"
    t.index ["status"], name: "index_transactions_on_status"
    t.index ["transaction_currency"], name: "index_transactions_on_transaction_currency"
    t.index ["transaction_date", "transaction_direction"], name: "index_transactions_on_date_and_direction"
    t.index ["transaction_date"], name: "index_transactions_on_transaction_date"
    t.index ["transaction_direction"], name: "index_transactions_on_transaction_direction"
    t.index ["transaction_type"], name: "index_transactions_on_transaction_type"
  end

  create_table "user_roles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "role_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["role_id"], name: "index_user_roles_on_role_id"
    t.index ["user_id", "role_id"], name: "index_user_roles_on_user_id_and_role_id", unique: true
    t.index ["user_id"], name: "index_user_roles_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "employee_id", null: false
    t.string "name", null: false
    t.string "email", null: false
    t.string "user_type", default: "viewer"
    t.boolean "is_creator", default: false
    t.boolean "is_approver", default: false
    t.decimal "approval_limit", precision: 15, scale: 2
    t.integer "primary_workshop_id"
    t.string "pin_code"
    t.boolean "active", default: true
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["active"], name: "index_users_on_active"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["employee_id"], name: "index_users_on_employee_id", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
    t.index ["user_type"], name: "index_users_on_user_type"
  end

  add_foreign_key "user_roles", "roles"
  add_foreign_key "user_roles", "users"
end
