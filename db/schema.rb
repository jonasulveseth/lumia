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

ActiveRecord::Schema[8.1].define(version: 2026_10_16_070040) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "ai_providers", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.string "provider_type", default: "ollama", null: false
    t.string "api_base_url", null: false
    t.text "api_key"
    t.string "chat_model"
    t.string "lightweight_model"
    t.boolean "is_default", default: false, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_ai_providers_on_slug", unique: true
  end

  create_table "approach_choices", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "approach_key", null: false
    t.string "stance", default: "resonates", null: false
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "approach_key"], name: "index_approach_choices_on_user_id_and_approach_key", unique: true
    t.index ["user_id"], name: "index_approach_choices_on_user_id"
  end

  create_table "check_ins", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.date "week_start", null: false
    t.jsonb "ratings", default: {}, null: false
    t.integer "energy"
    t.text "went_well"
    t.text "challenges"
    t.text "learned"
    t.text "next_focus"
    t.text "coach_reply"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "week_start"], name: "index_check_ins_on_user_id_and_week_start", unique: true
    t.index ["user_id"], name: "index_check_ins_on_user_id"
  end

  create_table "conversations", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "title"
    t.string "area_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "kind", default: "coach", null: false
    t.jsonb "profile_draft", default: {}, null: false
    t.index ["user_id", "kind"], name: "index_conversations_on_user_id_and_kind"
    t.index ["user_id"], name: "index_conversations_on_user_id"
  end

  create_table "documents", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "title", null: false
    t.string "kind", default: "lab_result", null: false
    t.date "taken_on"
    t.text "extracted_text"
    t.text "summary"
    t.string "status", default: "pending", null: false
    t.string "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_documents_on_user_id"
  end

  create_table "entries", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.text "body", null: false
    t.string "kind", default: "note", null: false
    t.string "area_keys", default: [], null: false, array: true
    t.string "source", default: "manual", null: false
    t.datetime "occurred_at", null: false
    t.datetime "processed_at"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "occurred_at"], name: "index_entries_on_user_id_and_occurred_at"
    t.index ["user_id"], name: "index_entries_on_user_id"
  end

  create_table "experiments", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "area_key"
    t.string "approach_key"
    t.string "title", null: false
    t.text "hypothesis"
    t.string "status", default: "running", null: false
    t.date "starts_on"
    t.date "ends_on"
    t.text "outcome"
    t.text "learning"
    t.integer "success_rating"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_experiments_on_user_id"
  end

  create_table "insights", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "title", null: false
    t.text "body", null: false
    t.string "kind", default: "pattern", null: false
    t.string "area_keys", default: [], null: false, array: true
    t.jsonb "evidence", default: {}, null: false
    t.string "status", default: "new", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_insights_on_user_id"
  end

  create_table "life_areas", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "area_key", null: false
    t.boolean "active", default: true, null: false
    t.integer "position", default: 0, null: false
    t.integer "rating"
    t.text "current_state"
    t.text "focus_goal"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "area_key"], name: "index_life_areas_on_user_id_and_area_key", unique: true
    t.index ["user_id"], name: "index_life_areas_on_user_id"
  end

  create_table "measurements", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "metric_key", null: false
    t.string "label"
    t.decimal "value", precision: 12, scale: 3, null: false
    t.string "unit"
    t.decimal "reference_low", precision: 12, scale: 3
    t.decimal "reference_high", precision: 12, scale: 3
    t.string "area_key"
    t.datetime "measured_at", null: false
    t.string "source_type"
    t.bigint "source_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["source_type", "source_id"], name: "index_measurements_on_source"
    t.index ["user_id", "metric_key", "measured_at"], name: "index_measurements_on_user_id_and_metric_key_and_measured_at"
    t.index ["user_id"], name: "index_measurements_on_user_id"
  end

  create_table "memories", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.text "content", null: false
    t.string "category", default: "fact", null: false
    t.string "area_key"
    t.string "source", default: "ai", null: false
    t.string "origin_type"
    t.bigint "origin_id"
    t.boolean "pinned", default: false, null: false
    t.datetime "archived_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["origin_type", "origin_id"], name: "index_memories_on_origin"
    t.index ["user_id"], name: "index_memories_on_user_id"
  end

  create_table "messages", force: :cascade do |t|
    t.bigint "conversation_id", null: false
    t.string "role", null: false
    t.text "content", default: "", null: false
    t.string "status", default: "done", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["conversation_id"], name: "index_messages_on_conversation_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.string "locale", default: "sv", null: false
    t.integer "birth_year"
    t.string "coach_style", default: "gentle", null: false
    t.text "about_me"
    t.datetime "onboarded_at"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "approach_choices", "users"
  add_foreign_key "check_ins", "users"
  add_foreign_key "conversations", "users"
  add_foreign_key "documents", "users"
  add_foreign_key "entries", "users"
  add_foreign_key "experiments", "users"
  add_foreign_key "insights", "users"
  add_foreign_key "life_areas", "users"
  add_foreign_key "measurements", "users"
  add_foreign_key "memories", "users"
  add_foreign_key "messages", "conversations"
  add_foreign_key "sessions", "users"
end
