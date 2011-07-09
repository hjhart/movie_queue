class TorrentsController < ApplicationController
  def list
    search_param = params['q']
    movie_id = params['m_id']
    movie = Movie.find(movie_id)
    movie.fetch_and_save_torrents(search_param)
    render text: "Okay!"
  end

  def index
    @movie = Movie.find(params[:movie_id])
    @torrents = @movie.torrents.sort_by { |t| -(t.seeds) }
  end
  
  def show
    torrent = Torrent.find(params[:id])
    download = Download.new(
        :url => torrent.link,
        :movie => torrent.movie,
        :status => Download::OPENED,
        :download_name => torrent.name,
        :torrent_id => torrent,
        :percent_done => 0
    )

    if(download.save)
      redirect_to movie_download_url torrent.movie, download
    else
      render :status => 500
    end
    
  end
end
