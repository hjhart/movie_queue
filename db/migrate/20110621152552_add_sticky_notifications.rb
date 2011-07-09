class AddStickyNotifications < ActiveRecord::Migration
  def up
    add_column :notifications, :sticky, :boolean, :default => false
    change_column :notifications, :read, :boolean, :default => false
  end



  def down
    remove_column :notifications, :sticky
  end
end
