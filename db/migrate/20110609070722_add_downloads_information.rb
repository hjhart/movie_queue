class AddDownloadsInformation < ActiveRecord::Migration
  def up
    add_column :downloads, :percent_done, :integer
    add_column :downloads, :filesize, :integer
    add_column :downloads, :date_created, :datetime
    add_column :downloads, :download_name, :string
    add_column :downloads, :hash, :string
    add_column :downloads, :eta, :integer
    add_column :downloads, :torrent_id, :integer
  end

  def down
   remove_column :downloads, :percent_done
   remove_column :downloads, :filesize
   remove_column :downloads, :date_created
   remove_column :downloads, :download_name
   remove_column :downloads, :hash
   remove_column :downloads, :eta
   remove_column :downloads, :torrent_id
  end
end
