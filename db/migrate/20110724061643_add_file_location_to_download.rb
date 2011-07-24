class AddFileLocationToDownload < ActiveRecord::Migration
  def up
    add_column :downloads, :download_location, :string
  end

  def down
    remove_column :downloads, :download_location
  end
end
