class ChangeTorrentCols < ActiveRecord::Migration
  def up
    change_column :torrents, :size, :bigint
  end

  def down
    change_column :torrents, :size, :integer
  end
end
