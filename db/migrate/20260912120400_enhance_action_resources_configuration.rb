class EnhanceActionResourcesConfiguration < ActiveRecord::Migration[8.1]
  def change
    change_table :action_resources, bulk: true do |t|
      t.references :public_service, null: true, foreign_key: true, type: :uuid
      t.text :instructions
      t.integer :position, null: false, default: 0
    end

    add_index :action_resources, [ :public_service_id, :resource_type, :position ], name: "index_action_resources_for_service"
  end
end
