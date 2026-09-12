class AlignServiceRuleConfigurationFields < ActiveRecord::Migration[8.1]
  def change
    rename_column :service_rules, :value, :duration_value
    rename_column :service_rules, :unit, :duration_unit
    add_column :service_rules, :name, :string
    add_column :service_rules, :description, :text
  end
end
