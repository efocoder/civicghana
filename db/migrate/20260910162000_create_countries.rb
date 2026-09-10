class CreateCountries < ActiveRecord::Migration[8.1]
  def change
    enable_extension "pgcrypto" unless extension_enabled?("pgcrypto")

    create_table :countries, id: :uuid do |t|
      t.string :name, null: false
      t.string :code, null: false
      t.boolean :active, null: false, default: true
      t.timestamps
    end

    add_index :countries, :code, unique: true
    add_check_constraint :countries, "char_length(code) = 2", name: "countries_code_length"
  end
end
