class DownloadsController < ApplicationController
  def index
    @movie = Movie.find(params[:movie_id])
  end

  def show
    download = Download.find(params[:id])
    download.status = Download::DOWNLOADING
    download.save
    download.download
    movie = download.movie
    movie.download_start=true
    movie.save
    Notification.create({:notification => "The download for '#{download.download_name} 'has begun.", :read => false})
    redirect_to root_path
  end
end
