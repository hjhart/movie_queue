class AddMovieInformation < ActiveRecord::Migration
  def up
    add_column :movies, :dvd_release_date, :date
    add_column :movies, :year, :string
    add_column :movies, :mpaa_rating, :string
    add_column :movies, :thumbnail_url, :string
    add_column :movies, :url, :string
    add_column :movies, :audience_score, :integer
    add_column :movies, :critics_score, :integer
    add_column :movies, :runtime, :integer
    add_column :movies, :search_term, :string
  end

  def down
    remove_column :movies, :dvd_release_date
    remove_column :movies, :year
    remove_column :movies, :mpaa_rating
    remove_column :movies, :thumbnail_url
    remove_column :movies, :url
    remove_column :movies, :audience_score
    remove_column :movies, :critics_score
    remove_column :movies, :runtime
    remove_column :movies, :search_term
  end
end
