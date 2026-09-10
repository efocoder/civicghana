class AddApplicationCompletedToCases < ActiveRecord::Migration[8.1]
  def change
    change_table :cases do |t|
      t.date :application_completed_on, null: false, default: "2026-01-01"
      t.date :portal_created_on
    end

    change_column_null :cases, :payment_date, true
  end
end
