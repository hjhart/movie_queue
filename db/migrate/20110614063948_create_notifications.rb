class CreateNotifications < ActiveRecord::Migration
  def change
    create_table :notifications do |t|
      t.string :notification
      t.boolean :read

      t.timestamps
    end
  end
end
