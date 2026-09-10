class CreateCaseObservations < ActiveRecord::Migration[8.1]
  def change
    create_table :case_observations, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :case, null: false, foreign_key: true, type: :uuid
      t.string :observation_type, null: false
      t.references :process_step, null: false, foreign_key: true, type: :uuid
      t.string :status, null: false
      t.date :observed_on, null: false

      t.timestamps
    end

    add_check_constraint :case_observations, "observed_on >= CURRENT_DATE - INTERVAL '10 years'",
      name: "case_observations_reasonable_observed_on"
  end
end
