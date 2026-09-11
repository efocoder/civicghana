class CreateCatalogLookups < ActiveRecord::Migration[8.1]
  def change
    create_table :regions, id: :uuid do |t|
      t.references :country, null: false, foreign_key: true, type: :uuid
      t.string :code, null: false
      t.string :name, null: false
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :regions, %i[country_id code], unique: true

    create_table :portal_statuses, id: :uuid do |t|
      t.references :public_service, null: false, foreign_key: true, type: :uuid
      t.string :code, null: false
      t.string :name, null: false
      t.integer :position, null: false, default: 0
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :portal_statuses, %i[public_service_id code], unique: true

    create_table :evidence_sources, id: :uuid do |t|
      t.string :code, null: false
      t.string :name, null: false
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :evidence_sources, :code, unique: true

    create_table :progress_claims, id: :uuid do |t|
      t.string :code, null: false
      t.string :name, null: false
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :progress_claims, :code, unique: true
  end
end
