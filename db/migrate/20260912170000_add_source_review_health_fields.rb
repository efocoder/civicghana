class AddSourceReviewHealthFields < ActiveRecord::Migration[8.1]
  def change
    add_column :sources, :http_status, :integer
    add_column :sources, :review_due_at, :datetime
    add_column :sources, :review_required, :boolean, default: false, null: false

    add_index :sources, :review_due_at
    add_index :sources, :review_required
  end
end
