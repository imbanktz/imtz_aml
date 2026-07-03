# db/schema.rb
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

ActiveRecord::Schema.define(version: 2026_07_03_000000) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  # ============================================================================
  # Users Table
  # ============================================================================
  create_table "users", force: :cascade do |t|
    t.string "employee_id"
    t.string "name"
    t.string "email"
    t.string "user_type"
    t.boolean "is_creator"
    t.boolean "is_approver"
    t.decimal "approval_limit"
    t.integer "primary_workshop_id"
    t.string "pin_code"
    t.boolean "active"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    
    # Devise fields
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count"
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["employee_id"], name: "index_users_on_employee_id", unique: true
  end

  # ============================================================================
  # Roles Table
  # ============================================================================
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

  # ============================================================================
  # User Roles Join Table (Many-to-Many)
  # ============================================================================
  create_table "user_roles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "role_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    
    t.index ["user_id", "role_id"], name: "index_user_roles_on_user_id_and_role_id", unique: true
    t.index ["user_id"], name: "index_user_roles_on_user_id"
    t.index ["role_id"], name: "index_user_roles_on_role_id"
  end

  # ============================================================================
  # Transactions Table (RTGS Transactions)
  # ============================================================================
  create_table "transactions", force: :cascade do |t|
    # Core identification fields
    t.string "request_id", null: false
    t.string "transaction_direction", null: false, default: "IN"
    t.string "transaction_type", default: "UNKNOWN"
    
    # Financial fields
    t.decimal "transaction_amount", precision: 18, scale: 2, null: false, default: 0
    t.string "transaction_currency", null: false, default: "TZS"
    t.date "transaction_date", null: false
    
    # Transaction metadata
    t.string "reference"
    t.text "narrative"
    t.string "bank_code"
    
    # Party information (Debtor and Creditor)
    t.json "parties"
    
    # Raw data storage
    t.json "raw_data"
    t.json "raw_fields"
    t.text "raw_message"
    
    # Status tracking
    t.string "status", default: "PENDING"
    t.string "screening_status", default: "PENDING"
    t.json "screening_result"
    t.text "screening_error"
    t.datetime "screened_at"
    
    # Error handling
    t.text "error_message"
    
    # Processing metadata
    t.datetime "processed_at"
    
    t.timestamps
  end

  # ============================================================================
  # Indexes
  # ============================================================================
  
  # Users indexes
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  add_index "users", ["email"], name: "index_users_on_email", unique: true
  add_index "users", ["employee_id"], name: "index_users_on_employee_id", unique: true
  
  # Roles indexes
  add_index "roles", ["code"], name: "index_roles_on_code", unique: true
  add_index "roles", ["name"], name: "index_roles_on_name", unique: true
  
  # User Roles indexes
  add_index "user_roles", ["user_id", "role_id"], name: "index_user_roles_on_user_id_and_role_id", unique: true
  add_index "user_roles", ["user_id"], name: "index_user_roles_on_user_id"
  add_index "user_roles", ["role_id"], name: "index_user_roles_on_role_id"
  
  # Transactions indexes
  add_index "transactions", ["request_id"], name: "index_transactions_on_request_id", unique: true
  add_index "transactions", ["transaction_direction"], name: "index_transactions_on_transaction_direction"
  add_index "transactions", ["transaction_type"], name: "index_transactions_on_transaction_type"
  add_index "transactions", ["transaction_date"], name: "index_transactions_on_transaction_date"
  add_index "transactions", ["transaction_currency"], name: "index_transactions_on_transaction_currency"
  add_index "transactions", ["reference"], name: "index_transactions_on_reference"
  add_index "transactions", ["status"], name: "index_transactions_on_status"
  add_index "transactions", ["screening_status"], name: "index_transactions_on_screening_status"
  add_index "transactions", ["transaction_date", "transaction_direction"], name: "index_transactions_on_date_and_direction"
  add_index "transactions", ["status", "screening_status"], name: "index_transactions_on_status_and_screening"

  # ============================================================================
  # Foreign Keys
  # ============================================================================
  add_foreign_key "user_roles", "users"
  add_foreign_key "user_roles", "roles"

end
