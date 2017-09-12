class CreateContacts < ActiveRecord::Migration[5.0]
  def change
    create_table :contacts do |t|
    	t.string :name, null: false
    	t.string :phone
      t.string :time_zone, null: false
    	t.integer :user_id, null: false

    	t.timestamps null: false
    end

    add_index :contacts, :user_id
  end
end
