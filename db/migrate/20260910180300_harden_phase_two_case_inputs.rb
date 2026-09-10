class HardenPhaseTwoCaseInputs < ActiveRecord::Migration[8.1]
  def change
    change_column_default :cases, :application_completed_on, from: "2026-01-01", to: nil
  end
end
