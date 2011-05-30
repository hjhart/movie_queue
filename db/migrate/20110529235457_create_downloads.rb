class CreateDownloads < ActiveRecord::Migration
  def change
    create_table :downloads do |t|
      t.string :url
      t.integer :movie_id
      t.integer :status

      t.timestamps
    end
  end
end
