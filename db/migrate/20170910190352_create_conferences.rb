class CreateConferences < ActiveRecord::Migration[5.0]
  def change
    create_table :conferences do |t|
      t.string :name, null: false
    	t.integer :user_id, null: false
    	t.datetime :start_time, null: false
    	t.datetime :end_time, null: false
      t.boolean :moderated, default: true
    	t.string :access_code
    	t.string :admin_pin, null: false
      t.string :conf_sid

    	t.timestamps null: false
    end
  end
end
