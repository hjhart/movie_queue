class CreateMovies < ActiveRecord::Migration
  def change
    create_table :movies do |t|
      t.string :name
      t.boolean :active
      t.boolean :download_start
      t.boolean :download_finish

      t.timestamps
    end
  end
end
