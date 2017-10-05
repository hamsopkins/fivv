class AddConferenceCountToUsers < ActiveRecord::Migration[5.0]
  def change
  	add_column :users, :conference_count, :integer, default: 0
  end
end
