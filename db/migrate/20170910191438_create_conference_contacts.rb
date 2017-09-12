class CreateConferenceContacts < ActiveRecord::Migration[5.0]
  def change
    create_table :conference_contacts do |t|
    	t.integer :conference_id, null: false
    	t.integer :contact_id, null: false
    	t.string :pin, null: false
      t.string :call_sid

    	t.timestamps null: false
    end

  	add_index :conference_contacts, [:conference_id, :call_sid]
  end
end
