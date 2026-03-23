class AddUserIdLink < ActiveRecord::Migration[8.1]
  def change
    change_table :links do |t|
      t.references :user, null: false, foreign_key: true
    end
  end
end
