class CreateProcessSteps < ActiveRecord::Migration[8.1]
  def change
    create_table :process_steps, id: :uuid do |t|
      t.references :public_service, null: false, foreign_key: true, type: :uuid
      t.references :source, null: true, foreign_key: true, type: :uuid
      t.string :name, null: false
      t.integer :sequence, null: false
      t.text :description, null: false
      t.timestamps
    end

    add_index :process_steps, %i[public_service_id sequence], unique: true
    add_check_constraint :process_steps, "sequence > 0", name: "process_steps_positive_sequence"
  end
end
