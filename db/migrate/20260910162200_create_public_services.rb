class CreatePublicServices < ActiveRecord::Migration[8.1]
  def change
    create_table :public_services, id: :uuid do |t|
      t.references :institution, null: false, foreign_key: true, type: :uuid
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description, null: false
      t.string :service_category, null: false
      t.boolean :active, null: false, default: true
      t.timestamps
    end

    add_index :public_services, :slug, unique: true
    add_index :public_services, %i[institution_id name], unique: true
  end
end
