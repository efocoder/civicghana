class ExtendCaseObservationsForEvidence < ActiveRecord::Migration[8.1]
  def change
    change_table :case_observations do |t|
      t.text :summary
      t.string :progress_claim
      t.uuid :reported_process_step_id
    end

    add_foreign_key :case_observations, :process_steps, column: :reported_process_step_id
    add_index :case_observations, :reported_process_step_id
  end
end
