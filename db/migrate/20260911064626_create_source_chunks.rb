class CreateSourceChunks < ActiveRecord::Migration[8.1]
  def change
    create_table :source_chunks, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :source, null: false, foreign_key: true, type: :uuid
      t.text :content, null: false
      t.string :section_label
      t.integer :position
      t.string :heading
      t.integer :page_number
      t.string :provision

      t.timestamps
    end

    add_index :source_chunks, :section_label
    add_index :source_chunks, :provision

    reversible do |dir|
      dir.up do
        execute "ALTER TABLE source_chunks ADD COLUMN content_tsv tsvector GENERATED ALWAYS AS (to_tsvector('english', content)) STORED"
        execute "CREATE INDEX index_source_chunks_on_content_tsv ON source_chunks USING gin(content_tsv)"
      end
    end
  end
end
