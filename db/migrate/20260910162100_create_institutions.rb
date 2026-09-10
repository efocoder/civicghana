class CreateInstitutions < ActiveRecord::Migration[8.1]
  def change
    create_table :institutions, id: :uuid do |t|
      t.references :country, null: false, foreign_key: true, type: :uuid
      t.string :name, null: false
      t.string :official_url, null: false
      t.text :description, null: false
      t.boolean :active, null: false, default: true
      t.timestamps
    end

    add_index :institutions, %i[country_id name], unique: true
  end
end
