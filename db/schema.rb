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

ActiveRecord::Schema[8.1].define(version: 2026_09_12_150000) do
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
    t.text "instructions"
    t.datetime "last_verified_at"
    t.string "name", null: false
    t.string "phone"
    t.integer "position", default: 0, null: false
    t.uuid "public_service_id"
    t.text "purpose", null: false
    t.string "resource_type", null: false
    t.uuid "source_id"
    t.datetime "updated_at", null: false
    t.string "url"
    t.index ["active"], name: "index_action_resources_on_active"
    t.index ["institution_id"], name: "index_action_resources_on_institution_id"
    t.index ["public_service_id", "resource_type", "position"], name: "index_action_resources_for_service"
    t.index ["public_service_id"], name: "index_action_resources_on_public_service_id"
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
    t.string "region"
    t.datetime "updated_at", null: false
    t.index ["public_service_id"], name: "index_cases_on_public_service_id"
  end

  create_table "catalog_translations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.text "instructions"
    t.string "locale", null: false
    t.string "name"
    t.string "section_label"
    t.text "summary"
    t.string "title"
    t.uuid "translatable_id", null: false
    t.string "translatable_type", null: false
    t.datetime "updated_at", null: false
    t.index ["translatable_type", "translatable_id", "locale"], name: "idx_catalog_translations_identity", unique: true
    t.index ["translatable_type", "translatable_id"], name: "idx_on_translatable_type_translatable_id_c3efaa6963"
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

  create_table "evidence_sources", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_evidence_sources_on_code", unique: true
  end

  create_table "institutions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.uuid "country_id", null: false
    t.datetime "created_at", null: false
    t.text "description", null: false
    t.string "name", null: false
    t.string "short_name"
    t.string "slug"
    t.datetime "updated_at", null: false
    t.string "website_url", null: false
    t.index ["country_id", "name"], name: "index_institutions_on_country_id_and_name", unique: true
    t.index ["country_id"], name: "index_institutions_on_country_id"
    t.index ["slug"], name: "index_institutions_on_slug", unique: true
  end

  create_table "organizational_units", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.uuid "institution_id", null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["institution_id", "code"], name: "index_organizational_units_on_institution_id_and_code", unique: true
    t.index ["institution_id", "position"], name: "index_organizational_units_on_institution_id_and_position"
    t.index ["institution_id"], name: "index_organizational_units_on_institution_id"
  end

  create_table "portal_statuses", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.uuid "public_service_id", null: false
    t.datetime "updated_at", null: false
    t.index ["public_service_id", "code"], name: "index_portal_statuses_on_public_service_id_and_code", unique: true
    t.index ["public_service_id"], name: "index_portal_statuses_on_public_service_id"
  end

  create_table "process_steps", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.text "description", null: false
    t.string "name", null: false
    t.integer "position", null: false
    t.uuid "public_service_id", null: false
    t.integer "sequence", null: false
    t.uuid "source_id"
    t.datetime "updated_at", null: false
    t.index ["public_service_id", "active", "position"], name: "index_process_steps_for_display"
    t.index ["public_service_id", "sequence"], name: "index_process_steps_on_public_service_id_and_sequence", unique: true
    t.index ["public_service_id"], name: "index_process_steps_on_public_service_id"
    t.index ["source_id"], name: "index_process_steps_on_source_id"
    t.check_constraint "sequence > 0", name: "process_steps_positive_sequence"
  end

  create_table "progress_claims", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_progress_claims_on_code", unique: true
  end

  create_table "public_services", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.boolean "case_enabled", default: true, null: false
    t.datetime "created_at", null: false
    t.text "description", null: false
    t.uuid "institution_id", null: false
    t.string "name", null: false
    t.uuid "organizational_unit_id"
    t.boolean "requires_region", default: false, null: false
    t.string "service_category", null: false
    t.string "service_code"
    t.string "slug", null: false
    t.string "support_level", default: "directory", null: false
    t.boolean "tracks_portal_milestones", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["institution_id", "name"], name: "index_public_services_on_institution_id_and_name", unique: true
    t.index ["institution_id"], name: "index_public_services_on_institution_id"
    t.index ["organizational_unit_id"], name: "index_public_services_on_organizational_unit_id"
    t.index ["service_code"], name: "index_public_services_on_service_code", unique: true
    t.index ["slug"], name: "index_public_services_on_slug", unique: true
    t.index ["support_level", "active"], name: "index_public_services_on_support_level_and_active"
    t.check_constraint "support_level::text = ANY (ARRAY['directory'::character varying, 'guided'::character varying, 'trackable'::character varying]::text[])", name: "public_services_valid_support_level"
  end

  create_table "regions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "code", null: false
    t.uuid "country_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["country_id", "code"], name: "index_regions_on_country_id_and_code", unique: true
    t.index ["country_id"], name: "index_regions_on_country_id"
  end

  create_table "requirements", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "category", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.boolean "mandatory", default: true, null: false
    t.integer "position", default: 0, null: false
    t.uuid "public_service_id", null: false
    t.uuid "service_variant_id"
    t.uuid "source_id"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["public_service_id", "service_variant_id", "position"], name: "index_requirements_for_service"
    t.index ["public_service_id"], name: "index_requirements_on_public_service_id"
    t.index ["service_variant_id"], name: "index_requirements_on_service_variant_id"
    t.index ["source_id"], name: "index_requirements_on_source_id"
  end

  create_table "service_fees", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.decimal "amount", precision: 14, scale: 2
    t.string "calculation_type", default: "fixed", null: false
    t.datetime "created_at", null: false
    t.string "currency", default: "GHS", null: false
    t.text "description"
    t.date "effective_from"
    t.date "effective_to"
    t.string "name", null: false
    t.uuid "public_service_id", null: false
    t.uuid "service_variant_id"
    t.uuid "source_id", null: false
    t.datetime "updated_at", null: false
    t.index ["public_service_id", "active"], name: "index_service_fees_on_public_service_id_and_active"
    t.index ["public_service_id"], name: "index_service_fees_on_public_service_id"
    t.index ["service_variant_id"], name: "index_service_fees_on_service_variant_id"
    t.index ["source_id"], name: "index_service_fees_on_source_id"
    t.check_constraint "amount IS NULL OR amount >= 0::numeric", name: "service_fees_nonnegative_amount"
    t.check_constraint "effective_to IS NULL OR effective_from IS NULL OR effective_to >= effective_from", name: "service_fees_valid_effective_period"
  end

  create_table "service_rules", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "anchor_event", default: "payment", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "duration_unit", null: false
    t.integer "duration_value", null: false
    t.date "effective_from", null: false
    t.date "effective_to"
    t.string "name"
    t.uuid "public_service_id", null: false
    t.string "rule_type", null: false
    t.uuid "source_id", null: false
    t.datetime "updated_at", null: false
    t.datetime "verified_at", null: false
    t.index ["public_service_id", "rule_type", "effective_from"], name: "index_service_rules_for_resolution"
    t.index ["public_service_id"], name: "index_service_rules_on_public_service_id"
    t.index ["source_id"], name: "index_service_rules_on_source_id"
    t.check_constraint "duration_value >= 0", name: "service_rules_nonnegative_value"
    t.check_constraint "effective_to IS NULL OR effective_to >= effective_from", name: "service_rules_valid_effective_period"
  end

  create_table "service_sources", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "primary", default: false, null: false
    t.uuid "public_service_id", null: false
    t.string "purpose", null: false
    t.uuid "source_id", null: false
    t.datetime "updated_at", null: false
    t.index ["public_service_id", "source_id"], name: "index_service_sources_on_public_service_id_and_source_id", unique: true
    t.index ["public_service_id"], name: "index_service_sources_on_public_service_id"
    t.index ["source_id"], name: "index_service_sources_on_source_id"
  end

  create_table "service_variants", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.uuid "public_service_id", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["public_service_id", "position"], name: "index_service_variants_on_public_service_id_and_position"
    t.index ["public_service_id", "slug"], name: "index_service_variants_on_public_service_id_and_slug", unique: true
    t.index ["public_service_id"], name: "index_service_variants_on_public_service_id"
  end

  create_table "source_chunks", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.text "content", null: false
    t.virtual "content_tsv", type: :tsvector, as: "to_tsvector('english'::regconfig, content)", stored: true
    t.datetime "created_at", null: false
    t.jsonb "embedding"
    t.string "heading"
    t.integer "page_number"
    t.integer "position"
    t.string "provision"
    t.uuid "public_service_id"
    t.string "section_label"
    t.uuid "source_id", null: false
    t.datetime "updated_at", null: false
    t.index ["content_tsv"], name: "index_source_chunks_on_content_tsv", using: :gin
    t.index ["provision"], name: "index_source_chunks_on_provision"
    t.index ["public_service_id", "active", "position"], name: "index_source_chunks_for_service"
    t.index ["public_service_id"], name: "index_source_chunks_on_public_service_id"
    t.index ["section_label"], name: "index_source_chunks_on_section_label"
    t.index ["source_id"], name: "index_source_chunks_on_source_id"
  end

  create_table "sources", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "authority_level"
    t.string "content_hash", null: false
    t.datetime "created_at", null: false
    t.date "effective_from"
    t.date "effective_to"
    t.datetime "last_verified_at", null: false
    t.string "provision"
    t.date "published_at"
    t.string "publisher", null: false
    t.string "source_type", null: false
    t.text "summary", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.string "url", null: false
    t.index ["content_hash"], name: "index_sources_on_content_hash"
    t.index ["url"], name: "index_sources_on_url", unique: true
    t.check_constraint "effective_to IS NULL OR effective_from IS NULL OR effective_to >= effective_from", name: "sources_valid_effective_period"
  end

  add_foreign_key "action_paths", "public_services"
  add_foreign_key "action_paths", "sources"
  add_foreign_key "action_resources", "institutions"
  add_foreign_key "action_resources", "public_services"
  add_foreign_key "action_resources", "sources"
  add_foreign_key "case_actions", "action_resources"
  add_foreign_key "case_actions", "cases"
  add_foreign_key "case_milestone_observations", "case_observations"
  add_foreign_key "case_milestone_observations", "process_steps"
  add_foreign_key "case_observations", "cases"
  add_foreign_key "case_observations", "process_steps", column: "reported_process_step_id"
  add_foreign_key "cases", "public_services"
  add_foreign_key "institutions", "countries"
  add_foreign_key "organizational_units", "institutions"
  add_foreign_key "portal_statuses", "public_services"
  add_foreign_key "process_steps", "public_services"
  add_foreign_key "process_steps", "sources"
  add_foreign_key "public_services", "institutions"
  add_foreign_key "public_services", "organizational_units"
  add_foreign_key "regions", "countries"
  add_foreign_key "requirements", "public_services"
  add_foreign_key "requirements", "service_variants"
  add_foreign_key "requirements", "sources"
  add_foreign_key "service_fees", "public_services"
  add_foreign_key "service_fees", "service_variants"
  add_foreign_key "service_fees", "sources"
  add_foreign_key "service_rules", "public_services"
  add_foreign_key "service_rules", "sources"
  add_foreign_key "service_sources", "public_services"
  add_foreign_key "service_sources", "sources"
  add_foreign_key "service_variants", "public_services"
  add_foreign_key "source_chunks", "public_services"
  add_foreign_key "source_chunks", "sources"
end
