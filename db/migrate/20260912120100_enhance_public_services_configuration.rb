class EnhancePublicServicesConfiguration < ActiveRecord::Migration[8.1]
  def change
    change_table :public_services, bulk: true do |t|
      t.string :service_code
      t.boolean :case_enabled, null: false, default: true
    end

    add_index :public_services, :service_code, unique: true
  end
end
