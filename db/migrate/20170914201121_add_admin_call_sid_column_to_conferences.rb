class AddAdminCallSidColumnToConferences < ActiveRecord::Migration[5.0]
  def change
  	add_column :conferences, :admin_call_sid, :string
  	add_index :conferences, :admin_call_sid
  end
end
