class AddSourceLastCheckedAt < ActiveRecord::Migration[8.1]
  def change
    add_column :sources, :last_checked_at, :datetime
  end
end
