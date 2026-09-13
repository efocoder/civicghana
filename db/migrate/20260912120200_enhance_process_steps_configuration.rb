class EnhanceProcessStepsConfiguration < ActiveRecord::Migration[8.1]
  def change
    add_column :process_steps, :position, :integer
    reversible do |direction|
      direction.up { execute "UPDATE process_steps SET position = sequence" }
    end
    change_column_null :process_steps, :position, false
    add_column :process_steps, :active, :boolean, null: false, default: true
    add_index :process_steps, [ :public_service_id, :active, :position ], name: "index_process_steps_for_display"
  end
end
