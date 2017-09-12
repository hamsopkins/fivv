class CreateUsers < ActiveRecord::Migration[5.0]
  def change
    create_table :users do |t|
    	t.string :name, null: false
    	t.string :phone, null: false
    	t.string :company
      t.string :time_zone, null: false
    	t.string :password_digest, null: false
      t.boolean :active_user, default: false
      t.timestamps null: false
    end

    add_index :users, :phone
  end
end
