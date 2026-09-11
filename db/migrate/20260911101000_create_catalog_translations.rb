class CreateCatalogTranslations < ActiveRecord::Migration[8.1]
  def change
    create_table :catalog_translations, id: :uuid do |t|
      t.string :translatable_type, null: false
      t.uuid :translatable_id, null: false
      t.string :locale, null: false
      t.string :name
      t.text :description
      t.string :title
      t.text :summary
      t.text :instructions
      t.string :section_label
      t.timestamps
    end
    add_index :catalog_translations, %i[translatable_type translatable_id locale], unique: true, name: "idx_catalog_translations_identity"
    add_index :catalog_translations, %i[translatable_type translatable_id]
  end
end
