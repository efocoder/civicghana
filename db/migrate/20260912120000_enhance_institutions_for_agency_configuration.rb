class EnhanceInstitutionsForAgencyConfiguration < ActiveRecord::Migration[8.1]
  def change
    rename_column :institutions, :official_url, :website_url

    change_table :institutions, bulk: true do |t|
      t.string :slug
      t.string :short_name
    end

    add_index :institutions, :slug, unique: true
  end
end
