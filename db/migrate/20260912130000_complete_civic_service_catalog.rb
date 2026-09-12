class CompleteCivicServiceCatalog < ActiveRecord::Migration[8.1]
  def change
    create_table :organizational_units, id: :uuid do |t|
      t.references :institution, null: false, foreign_key: true, type: :uuid
      t.string :name, null: false
      t.string :code, null: false
      t.text :description
      t.integer :position, null: false, default: 0
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :organizational_units, %i[institution_id code], unique: true
    add_index :organizational_units, %i[institution_id position]

    add_reference :public_services, :organizational_unit, type: :uuid, foreign_key: true
    add_column :public_services, :support_level, :string, null: false, default: "directory"
    add_column :public_services, :tracks_portal_milestones, :boolean, null: false, default: false
    add_column :public_services, :requires_region, :boolean, null: false, default: false
    add_index :public_services, %i[support_level active]
    add_check_constraint :public_services,
      "support_level IN ('directory', 'guided', 'trackable')",
      name: "public_services_valid_support_level"

    create_table :service_variants, id: :uuid do |t|
      t.references :public_service, null: false, foreign_key: true, type: :uuid
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.integer :position, null: false, default: 0
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :service_variants, %i[public_service_id slug], unique: true
    add_index :service_variants, %i[public_service_id position]

    create_table :requirements, id: :uuid do |t|
      t.references :public_service, null: false, foreign_key: true, type: :uuid
      t.references :service_variant, foreign_key: true, type: :uuid
      t.references :source, foreign_key: true, type: :uuid
      t.string :category, null: false
      t.string :title, null: false
      t.text :description
      t.integer :position, null: false, default: 0
      t.boolean :mandatory, null: false, default: true
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :requirements, %i[public_service_id service_variant_id position], name: "index_requirements_for_service"

    create_table :service_fees, id: :uuid do |t|
      t.references :public_service, null: false, foreign_key: true, type: :uuid
      t.references :service_variant, foreign_key: true, type: :uuid
      t.references :source, null: false, foreign_key: true, type: :uuid
      t.string :name, null: false
      t.decimal :amount, precision: 14, scale: 2
      t.string :currency, null: false, default: "GHS"
      t.string :calculation_type, null: false, default: "fixed"
      t.text :description
      t.date :effective_from
      t.date :effective_to
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :service_fees, %i[public_service_id active]
    add_check_constraint :service_fees, "amount IS NULL OR amount >= 0", name: "service_fees_nonnegative_amount"
    add_check_constraint :service_fees,
      "effective_to IS NULL OR effective_from IS NULL OR effective_to >= effective_from",
      name: "service_fees_valid_effective_period"

    change_column_null :cases, :region, true
  end
end
