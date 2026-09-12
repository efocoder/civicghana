class CreateServiceSources < ActiveRecord::Migration[8.1]
  def change
    create_table :service_sources, id: :uuid do |t|
      t.references :public_service, null: false, foreign_key: true, type: :uuid
      t.references :source, null: false, foreign_key: true, type: :uuid
      t.string :purpose, null: false
      t.boolean :primary, null: false, default: false
      t.timestamps
    end

    add_index :service_sources, [:public_service_id, :source_id], unique: true
  end
end
