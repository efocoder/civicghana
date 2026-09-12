class EnhanceSourceChunksConfiguration < ActiveRecord::Migration[8.1]
  def change
    change_table :source_chunks, bulk: true do |t|
      t.references :public_service, null: true, foreign_key: true, type: :uuid
      t.boolean :active, null: false, default: true
      t.jsonb :embedding
    end

    add_index :source_chunks, [:public_service_id, :active, :position], name: "index_source_chunks_for_service"
  end
end
