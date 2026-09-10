class CreateCases < ActiveRecord::Migration[8.1]
  def change
    create_table :cases, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :public_service, null: false, foreign_key: true, type: :uuid
      t.string :region, null: false
      t.date :payment_date, null: false

      t.timestamps
    end
  end
end
