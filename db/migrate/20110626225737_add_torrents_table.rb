class AddTorrentsTable < ActiveRecord::Migration
  def up
    create_table :torrents do |t|
      t.integer :movie_id
      t.string :name
      t.integer :seeds
      t.integer :leeches
      t.string :link
      t.integer :size

      t.timestamps
    end
  end

  def down
    drop_table :torrents
  end
end
