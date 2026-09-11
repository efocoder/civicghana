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

ActiveRecord::Schema[8.1].define(version: 2026_09_11_064626) do
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

  create_table "action_resources", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "email"
    t.uuid "institution_id", null: false
    t.datetime "last_verified_at"
    t.string "name", null: false
    t.string "phone"
    t.text "purpose", null: false
    t.string "resource_type", null: false
    t.uuid "source_id"
    t.datetime "updated_at", null: false
    t.string "url"
    t.index ["active"], name: "index_action_resources_on_active"
    t.index ["institution_id"], name: "index_action_resources_on_institution_id"
    t.index ["resource_type"], name: "index_action_resources_on_resource_type"
    t.index ["source_id"], name: "index_action_resources_on_source_id"
  end

  create_table "case_actions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "action_resource_id"
    t.string "action_type", null: false
    t.uuid "case_id", null: false
    t.datetime "created_at", null: false
    t.text "notes"
    t.string "outcome"
    t.date "recommended_on", null: false
    t.string "status", default: "recommended", null: false
    t.date "taken_on"
    t.datetime "updated_at", null: false
    t.index ["action_resource_id"], name: "index_case_actions_on_action_resource_id"
    t.index ["action_type"], name: "index_case_actions_on_action_type"
    t.index ["case_id", "action_type"], name: "index_case_actions_on_case_id_and_action_type"
    t.index ["case_id"], name: "index_case_actions_on_case_id"
    t.index ["status"], name: "index_case_actions_on_status"
  end

  create_table "case_milestone_observations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "case_observation_id", null: false
    t.datetime "created_at", null: false
    t.uuid "process_step_id", null: false
    t.string "status", null: false
    t.datetime "updated_at", null: false
    t.index ["case_observation_id", "process_step_id"], name: "idx_milestone_obs_per_snapshot", unique: true
    t.index ["case_observation_id"], name: "index_case_milestone_observations_on_case_observation_id"
    t.index ["process_step_id"], name: "index_case_milestone_observations_on_process_step_id"
  end

  create_table "case_observations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "case_id", null: false
    t.datetime "created_at", null: false
    t.string "observation_type", null: false
    t.date "observed_on", null: false
    t.string "overall_status"
    t.string "progress_claim"
    t.uuid "reported_process_step_id"
    t.text "summary"
    t.datetime "updated_at", null: false
    t.index ["case_id"], name: "index_case_observations_on_case_id"
    t.index ["reported_process_step_id"], name: "index_case_observations_on_reported_process_step_id"
    t.check_constraint "observed_on >= (CURRENT_DATE - 'P10Y'::interval)", name: "case_observations_reasonable_observed_on"
  end

  create_table "cases", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.date "application_completed_on", null: false
    t.datetime "created_at", null: false
    t.date "payment_date"
    t.date "portal_created_on"
    t.uuid "public_service_id", null: false
    t.string "region", null: false
    t.datetime "updated_at", null: false
    t.index ["public_service_id"], name: "index_cases_on_public_service_id"
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
    t.string "anchor_event", default: "payment", null: false
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

  create_table "source_chunks", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "content", null: false
    t.virtual "content_tsv", type: :tsvector, as: "to_tsvector('english'::regconfig, content)", stored: true
    t.datetime "created_at", null: false
    t.string "heading"
    t.integer "page_number"
    t.integer "position"
    t.string "provision"
    t.string "section_label"
    t.uuid "source_id", null: false
    t.datetime "updated_at", null: false
    t.index ["content_tsv"], name: "index_source_chunks_on_content_tsv", using: :gin
    t.index ["provision"], name: "index_source_chunks_on_provision"
    t.index ["section_label"], name: "index_source_chunks_on_section_label"
    t.index ["source_id"], name: "index_source_chunks_on_source_id"
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
  add_foreign_key "action_resources", "institutions"
  add_foreign_key "action_resources", "sources"
  add_foreign_key "case_actions", "action_resources"
  add_foreign_key "case_actions", "cases"
  add_foreign_key "case_milestone_observations", "case_observations"
  add_foreign_key "case_milestone_observations", "process_steps"
  add_foreign_key "case_observations", "cases"
  add_foreign_key "case_observations", "process_steps", column: "reported_process_step_id"
  add_foreign_key "cases", "public_services"
  add_foreign_key "institutions", "countries"
  add_foreign_key "process_steps", "public_services"
  add_foreign_key "process_steps", "sources"
  add_foreign_key "public_services", "institutions"
  add_foreign_key "service_rules", "public_services"
  add_foreign_key "service_rules", "sources"
  add_foreign_key "source_chunks", "sources"
end
