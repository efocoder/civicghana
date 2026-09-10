class AddAnchorEventToServiceRules < ActiveRecord::Migration[8.1]
  def change
    add_column :service_rules, :anchor_event, :string, null: false, default: "payment"
  end
end
