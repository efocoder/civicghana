class AlignSourceConfigurationFields < ActiveRecord::Migration[8.1]
  def change
    rename_column :sources, :authority_type, :source_type
    rename_column :sources, :section_label, :provision
    rename_column :sources, :verified_at, :last_verified_at
    add_column :sources, :authority_level, :string
  end
end
