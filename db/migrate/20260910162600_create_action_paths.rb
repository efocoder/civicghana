class CreateActionPaths < ActiveRecord::Migration[8.1]
  def change
    create_table :action_paths, id: :uuid do |t|
      t.references :public_service, null: false, foreign_key: true, type: :uuid
      t.references :source, null: false, foreign_key: true, type: :uuid
      t.integer :sequence, null: false
      t.string :action_type, null: false
      t.string :title, null: false
      t.text :instructions, null: false
      t.jsonb :conditions, null: false, default: {}
      t.boolean :active, null: false, default: true
      t.timestamps
    end

    add_index :action_paths, %i[public_service_id sequence], unique: true
    add_index :action_paths, :conditions, using: :gin
    add_check_constraint :action_paths, "sequence > 0", name: "action_paths_positive_sequence"
  end
end
