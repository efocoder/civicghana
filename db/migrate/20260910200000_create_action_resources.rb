class CreateActionResources < ActiveRecord::Migration[8.1]
  def change
    create_table :action_resources, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :institution, null: false, foreign_key: true, type: :uuid
      t.references :source, foreign_key: true, type: :uuid
      t.string :name, null: false
      t.string :resource_type, null: false
      t.text :purpose, null: false
      t.string :url
      t.string :phone
      t.string :email
      t.datetime :last_verified_at
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :action_resources, :resource_type
    add_index :action_resources, :active
  end
end
