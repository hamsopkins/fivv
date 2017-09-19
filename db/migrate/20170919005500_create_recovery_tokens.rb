class CreateRecoveryTokens < ActiveRecord::Migration[5.0]
  def change
    create_table :recovery_tokens do |t|
    	t.string :token, null: false
    	t.integer :user_id, null: false
      t.timestamps
    end
    add_index :recovery_tokens, :user_id, unique: true
  end
end
