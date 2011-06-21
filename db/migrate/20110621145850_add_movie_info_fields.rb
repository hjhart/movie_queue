class AddMovieInfoFields < ActiveRecord::Migration
  def up
    add_column :movies, :api_queried, :boolean
  end

  def down
    remove_column :movies, :api_queried
  end
end
