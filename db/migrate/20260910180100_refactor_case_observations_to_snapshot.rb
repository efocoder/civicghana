class RefactorCaseObservationsToSnapshot < ActiveRecord::Migration[8.1]
  def change
    create_table :case_milestone_observations, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :case_observation, null: false, foreign_key: true, type: :uuid
      t.references :process_step, null: false, foreign_key: true, type: :uuid
      t.string :status, null: false

      t.timestamps
    end

    add_index :case_milestone_observations, %i[case_observation_id process_step_id],
      unique: true, name: "idx_milestone_obs_per_snapshot"

    change_table :case_observations do |t|
      t.string :overall_status
      t.remove :process_step_id
      t.remove :status
    end
  end
end
