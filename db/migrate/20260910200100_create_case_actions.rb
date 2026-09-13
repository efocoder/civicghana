class CreateCaseActions < ActiveRecord::Migration[8.1]
  def change
    create_table :case_actions, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :case, null: false, foreign_key: true, type: :uuid
      t.references :action_resource, foreign_key: true, type: :uuid
      t.string :action_type, null: false
      t.string :status, null: false, default: "recommended"
      t.date :recommended_on, null: false
      t.date :taken_on
      t.string :outcome
      t.text :notes

      t.timestamps
    end

    add_index :case_actions, :action_type
    add_index :case_actions, :status
    add_index :case_actions, [ :case_id, :action_type ]
  end
end
