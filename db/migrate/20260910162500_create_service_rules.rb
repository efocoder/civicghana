class CreateServiceRules < ActiveRecord::Migration[8.1]
  def change
    create_table :service_rules, id: :uuid do |t|
      t.references :public_service, null: false, foreign_key: true, type: :uuid
      t.references :source, null: false, foreign_key: true, type: :uuid
      t.string :rule_type, null: false
      t.integer :value, null: false
      t.string :unit, null: false
      t.date :effective_from, null: false
      t.date :effective_to
      t.datetime :verified_at, null: false
      t.boolean :active, null: false, default: true
      t.timestamps
    end

    add_index :service_rules, %i[public_service_id rule_type effective_from],
      name: "index_service_rules_for_resolution"
    add_check_constraint :service_rules, "value >= 0", name: "service_rules_nonnegative_value"
    add_check_constraint :service_rules,
      "effective_to IS NULL OR effective_to >= effective_from",
      name: "service_rules_valid_effective_period"
  end
end
