class EnlargeTextFieldsInTorrents < ActiveRecord::Migration
  def up
    change_column :torrents, :name, :text
    change_column :torrents, :link, :text
  end

  def down
    change_column :torrents, :name, :string
    change_column :torrents, :link, :string
  end
end
