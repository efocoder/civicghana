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

ActiveRecord::Schema[8.1].define(version: 2026_09_10_162600) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "action_paths", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "action_type", null: false
    t.boolean "active", default: true, null: false
    t.jsonb "conditions", default: {}, null: false
    t.datetime "created_at", null: false
    t.text "instructions", null: false
    t.uuid "public_service_id", null: false
    t.integer "sequence", null: false
    t.uuid "source_id", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["conditions"], name: "index_action_paths_on_conditions", using: :gin
    t.index ["public_service_id", "sequence"], name: "index_action_paths_on_public_service_id_and_sequence", unique: true
    t.index ["public_service_id"], name: "index_action_paths_on_public_service_id"
    t.index ["source_id"], name: "index_action_paths_on_source_id"
    t.check_constraint "sequence > 0", name: "action_paths_positive_sequence"
  end

  create_table "countries", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_countries_on_code", unique: true
    t.check_constraint "char_length(code::text) = 2", name: "countries_code_length"
  end

  create_table "institutions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.uuid "country_id", null: false
    t.datetime "created_at", null: false
    t.text "description", null: false
    t.string "name", null: false
    t.string "official_url", null: false
    t.datetime "updated_at", null: false
    t.index ["country_id", "name"], name: "index_institutions_on_country_id_and_name", unique: true
    t.index ["country_id"], name: "index_institutions_on_country_id"
  end

  create_table "process_steps", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description", null: false
    t.string "name", null: false
    t.uuid "public_service_id", null: false
    t.integer "sequence", null: false
    t.uuid "source_id"
    t.datetime "updated_at", null: false
    t.index ["public_service_id", "sequence"], name: "index_process_steps_on_public_service_id_and_sequence", unique: true
    t.index ["public_service_id"], name: "index_process_steps_on_public_service_id"
    t.index ["source_id"], name: "index_process_steps_on_source_id"
    t.check_constraint "sequence > 0", name: "process_steps_positive_sequence"
  end

  create_table "public_services", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.text "description", null: false
    t.uuid "institution_id", null: false
    t.string "name", null: false
    t.string "service_category", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["institution_id", "name"], name: "index_public_services_on_institution_id_and_name", unique: true
    t.index ["institution_id"], name: "index_public_services_on_institution_id"
    t.index ["slug"], name: "index_public_services_on_slug", unique: true
  end

  create_table "service_rules", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.date "effective_from", null: false
    t.date "effective_to"
    t.uuid "public_service_id", null: false
    t.string "rule_type", null: false
    t.uuid "source_id", null: false
    t.string "unit", null: false
    t.datetime "updated_at", null: false
    t.integer "value", null: false
    t.datetime "verified_at", null: false
    t.index ["public_service_id", "rule_type", "effective_from"], name: "index_service_rules_for_resolution"
    t.index ["public_service_id"], name: "index_service_rules_on_public_service_id"
    t.index ["source_id"], name: "index_service_rules_on_source_id"
    t.check_constraint "effective_to IS NULL OR effective_to >= effective_from", name: "service_rules_valid_effective_period"
    t.check_constraint "value >= 0", name: "service_rules_nonnegative_value"
  end

  create_table "sources", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "authority_type", null: false
    t.string "content_hash", null: false
    t.datetime "created_at", null: false
    t.date "effective_from"
    t.date "effective_to"
    t.date "published_at"
    t.string "publisher", null: false
    t.string "section_label"
    t.text "summary", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.string "url", null: false
    t.datetime "verified_at", null: false
    t.index ["content_hash"], name: "index_sources_on_content_hash"
    t.index ["url"], name: "index_sources_on_url", unique: true
    t.check_constraint "effective_to IS NULL OR effective_from IS NULL OR effective_to >= effective_from", name: "sources_valid_effective_period"
  end

  add_foreign_key "action_paths", "public_services"
  add_foreign_key "action_paths", "sources"
  add_foreign_key "institutions", "countries"
  add_foreign_key "process_steps", "public_services"
  add_foreign_key "process_steps", "sources"
  add_foreign_key "public_services", "institutions"
  add_foreign_key "service_rules", "public_services"
  add_foreign_key "service_rules", "sources"
end
