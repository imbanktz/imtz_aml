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

ActiveRecord::Schema.define(version: 2026_04_29_082433) do

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

  create_table "asset_categories", force: :cascade do |t|
    t.string "code"
    t.string "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "asset_makes", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "asset_models", force: :cascade do |t|
    t.bigint "asset_make_id"
    t.bigint "asset_type_id"
    t.string "model_code", null: false
    t.string "model_name"
    t.integer "engine_power_hp"
    t.integer "operating_weight_kg"
    t.integer "fuel_tank_capacity_liters"
    t.boolean "active", default: true
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["asset_make_id"], name: "index_asset_models_on_asset_make_id"
    t.index ["asset_type_id"], name: "index_asset_models_on_asset_type_id"
    t.index ["model_code"], name: "index_asset_models_on_model_code"
  end

  create_table "asset_types", force: :cascade do |t|
    t.bigint "asset_category_id"
    t.string "type_code", null: false
    t.string "type_name", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "typical_lifespan_hours"
    t.boolean "active", default: true
    t.index ["asset_category_id"], name: "index_asset_types_on_asset_category_id"
    t.index ["type_code"], name: "index_asset_types_on_type_code", unique: true
  end

  create_table "assets", force: :cascade do |t|
    t.string "fleet_number", null: false
    t.string "serial_number"
    t.bigint "asset_model_id"
    t.string "current_status"
    t.string "current_location_type"
    t.integer "current_location_id"
    t.decimal "current_hour_meter", precision: 10, scale: 1, default: "0.0"
    t.date "last_meter_update"
    t.date "acquisition_date"
    t.decimal "acquisition_cost", precision: 15, scale: 2
    t.integer "primary_operator_id"
    t.boolean "active", default: true
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["asset_model_id"], name: "index_assets_on_asset_model_id"
    t.index ["fleet_number"], name: "index_assets_on_fleet_number", unique: true
    t.index ["primary_operator_id"], name: "index_assets_on_primary_operator_id"
    t.index ["serial_number"], name: "index_assets_on_serial_number", unique: true
  end

  create_table "breakdown_reasons", force: :cascade do |t|
    t.string "reason_code"
    t.string "reason_name"
    t.string "category"
    t.text "typical_parts"
    t.decimal "average_repair_hours"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "farm_fields", force: :cascade do |t|
    t.bigint "farm_id", null: false
    t.string "field_name"
    t.string "field_code"
    t.decimal "area_hectares"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["farm_id"], name: "index_farm_fields_on_farm_id"
  end

  create_table "farms", force: :cascade do |t|
    t.string "farm_code"
    t.string "farm_name"
    t.string "farm_category"
    t.string "region"
    t.decimal "area_hectares"
    t.integer "manager_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "hour_meter_readings", force: :cascade do |t|
    t.bigint "asset_id"
    t.date "reading_date"
    t.decimal "hour_meter", precision: 10, scale: 1
    t.bigint "recorded_by_id"
    t.boolean "verified", default: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "verified_by_id"
    t.datetime "verified_at"
    t.text "notes"
    t.string "reading_type", default: "regular"
    t.index ["asset_id", "reading_date"], name: "index_hour_meter_readings_on_asset_id_and_reading_date", unique: true
    t.index ["asset_id"], name: "index_hour_meter_readings_on_asset_id"
    t.index ["reading_date"], name: "index_hour_meter_readings_on_reading_date"
    t.index ["recorded_by_id"], name: "index_hour_meter_readings_on_recorded_by_id"
  end

  create_table "lubricant_consumptions", force: :cascade do |t|
    t.date "transaction_date"
    t.bigint "asset_id"
    t.bigint "work_order_id"
    t.string "job_card_number"
    t.string "lubricant_type"
    t.decimal "quantity", precision: 10, scale: 2
    t.string "remark"
    t.string "reason"
    t.bigint "recorded_by_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["asset_id"], name: "index_lubricant_consumptions_on_asset_id"
    t.index ["lubricant_type"], name: "index_lubricant_consumptions_on_lubricant_type"
    t.index ["recorded_by_id"], name: "index_lubricant_consumptions_on_recorded_by_id"
    t.index ["transaction_date"], name: "index_lubricant_consumptions_on_transaction_date"
    t.index ["work_order_id"], name: "index_lubricant_consumptions_on_work_order_id"
  end

  create_table "lubricants", force: :cascade do |t|
    t.string "code"
    t.string "name"
    t.string "unit"
    t.decimal "current_stock"
    t.decimal "min_stock_level"
    t.decimal "unit_cost"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "monthly_availabilities", force: :cascade do |t|
    t.bigint "asset_id", null: false
    t.date "month"
    t.decimal "downtime_hours"
    t.decimal "breakdown_hours"
    t.decimal "pm_hours"
    t.decimal "waiting_parts_hours"
    t.text "notes"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["asset_id"], name: "index_monthly_availabilities_on_asset_id"
  end

  create_table "parts", force: :cascade do |t|
    t.string "part_number"
    t.string "part_name"
    t.string "applicable_make"
    t.string "applicable_model"
    t.integer "minimum_stock"
    t.integer "current_stock"
    t.integer "reorder_level"
    t.decimal "unit_cost"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "pm_schedules", force: :cascade do |t|
    t.string "name"
    t.string "equipment_category"
    t.integer "trigger_hours"
    t.jsonb "checklist_template"
    t.decimal "estimated_hours"
    t.boolean "active"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "transactions", force: :cascade do |t|
    t.datetime "date"
    t.string "request_id"
    t.string "transaction_direction"
    t.decimal "transaction_amount", precision: 18, scale: 2
    t.string "transaction_currency"
    t.date "transaction_date"
    t.string "clearing_system_ref"
    t.jsonb "parties", default: []
    t.jsonb "agents", default: []
    t.jsonb "narratives", default: {}
    t.jsonb "forensic_data", default: {}
    t.string "processing_type"
    t.string "profile"
    t.string "profile_name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["agents"], name: "index_transactions_on_agents", using: :gin
    t.index ["narratives"], name: "index_transactions_on_narratives", using: :gin
    t.index ["parties"], name: "index_transactions_on_parties", using: :gin
    t.index ["processing_type"], name: "index_transactions_on_processing_type"
    t.index ["request_id"], name: "index_transactions_on_request_id"
    t.index ["transaction_date", "transaction_currency"], name: "index_transactions_on_transaction_date_and_transaction_currency"
    t.index ["transaction_direction"], name: "index_transactions_on_transaction_direction"
  end

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
  end

  create_table "wo_lubricants", force: :cascade do |t|
    t.bigint "work_order_id", null: false
    t.bigint "lubricant_id", null: false
    t.decimal "quantity_used"
    t.decimal "unit_cost"
    t.decimal "total_cost"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["lubricant_id"], name: "index_wo_lubricants_on_lubricant_id"
    t.index ["work_order_id"], name: "index_wo_lubricants_on_work_order_id"
  end

  create_table "wo_parts", force: :cascade do |t|
    t.bigint "work_order_id", null: false
    t.bigint "part_id", null: false
    t.integer "quantity_used"
    t.decimal "unit_cost"
    t.decimal "total_cost"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["part_id"], name: "index_wo_parts_on_part_id"
    t.index ["work_order_id"], name: "index_wo_parts_on_work_order_id"
  end

  create_table "work_orders", force: :cascade do |t|
    t.string "wo_number", null: false
    t.bigint "asset_id"
    t.string "wo_type"
    t.string "priority"
    t.bigint "breakdown_reason_id"
    t.text "defect_description"
    t.decimal "meter_at_report", precision: 10, scale: 1
    t.decimal "meter_at_start", precision: 10, scale: 1
    t.decimal "meter_at_completion", precision: 10, scale: 1
    t.string "status", default: "reported"
    t.bigint "reported_by_id"
    t.datetime "reported_at"
    t.integer "assigned_mechanic_id"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.decimal "total_cost", precision: 15, scale: 2
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["asset_id"], name: "index_work_orders_on_asset_id"
    t.index ["assigned_mechanic_id"], name: "index_work_orders_on_assigned_mechanic_id"
    t.index ["breakdown_reason_id"], name: "index_work_orders_on_breakdown_reason_id"
    t.index ["reported_by_id"], name: "index_work_orders_on_reported_by_id"
    t.index ["status"], name: "index_work_orders_on_status"
    t.index ["wo_number"], name: "index_work_orders_on_wo_number", unique: true
  end

  create_table "workshop_sections", force: :cascade do |t|
    t.bigint "workshop_id", null: false
    t.string "section_code"
    t.string "section_name"
    t.string "section_type"
    t.integer "capacity"
    t.boolean "active"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["workshop_id"], name: "index_workshop_sections_on_workshop_id"
  end

  create_table "workshops", force: :cascade do |t|
    t.string "code"
    t.string "name"
    t.text "address"
    t.integer "manager_id"
    t.boolean "active"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  add_foreign_key "asset_models", "asset_makes"
  add_foreign_key "asset_models", "asset_types"
  add_foreign_key "asset_types", "asset_categories"
  add_foreign_key "assets", "asset_models"
  add_foreign_key "farm_fields", "farms"
  add_foreign_key "hour_meter_readings", "assets"
  add_foreign_key "hour_meter_readings", "users", column: "recorded_by_id"
  add_foreign_key "lubricant_consumptions", "assets"
  add_foreign_key "lubricant_consumptions", "users", column: "recorded_by_id"
  add_foreign_key "lubricant_consumptions", "work_orders"
  add_foreign_key "monthly_availabilities", "assets"
  add_foreign_key "wo_lubricants", "lubricants"
  add_foreign_key "wo_lubricants", "work_orders"
  add_foreign_key "wo_parts", "parts"
  add_foreign_key "wo_parts", "work_orders"
  add_foreign_key "work_orders", "assets"
  add_foreign_key "work_orders", "breakdown_reasons"
  add_foreign_key "work_orders", "users", column: "reported_by_id"
  add_foreign_key "workshop_sections", "workshops"
end
