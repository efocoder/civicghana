class CreateSources < ActiveRecord::Migration[8.1]
  def change
    create_table :sources, id: :uuid do |t|
      t.string :publisher, null: false
      t.string :title, null: false
      t.string :url, null: false
      t.string :authority_type, null: false
      t.string :section_label
      t.text :summary, null: false
      t.date :published_at
      t.datetime :verified_at, null: false
      t.date :effective_from
      t.date :effective_to
      t.string :content_hash, null: false
      t.boolean :active, null: false, default: true
      t.timestamps
    end

    add_index :sources, :url, unique: true
    add_index :sources, :content_hash
    add_check_constraint :sources,
      "effective_to IS NULL OR effective_from IS NULL OR effective_to >= effective_from",
      name: "sources_valid_effective_period"
  end
end
