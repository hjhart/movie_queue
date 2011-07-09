class Torrent < ActiveRecord::Base
  belongs_to :movie

  @queue = 'torrent_queue'

  def self.perform(id, search_term=nil, service=:pirate_bay, auto_download=true)

    movie = Movie.find(id)
    t = TorrentApi.new(service.to_sym)
    t.search_term = search_term.nil? ? movie.search_term : search_term
    if results = t.search
      download_result = nil

      results.each do |result|
        puts "Creating a torrent for movie #{movie.search_term} and torrent #{result.name}"
        Torrent.create({
                           :movie => movie,
                           :name => result.name,
                           :seeds => result.seeds,
                           :leeches => result.leeches,
                           :link => result.link,
                           :size => result.size.to_i
                       })
        if Movie.qualifies result
          download_result = result
          break if auto_download
        end
      end

      if auto_download == false && results.size > 0
        link = "/movies/#{movie.id}/torrents"
        Notification.create(:notification => "Received #{results.size} results for search #{search_term}. <a href=\"#{link}\">Click here</a> to view them.", :sticky => true)
      end

      if download_result && auto_download
        puts "Found a qualifying torrent for #{movie} @ #{download_result.link}"
        d = Download.create(:url => download_result.link, :movie => movie, :status => Download::DOWNLOADING, :download_name => download_result.name)
        d.download
        movie.update_attributes({:download_start => true})
        Notification.create(:notification => "Found a download for '#{movie.search_term}': #{download_result.link}", :sticky => true)
      end
    else
      link = "/movies/#{movie.id}/edit"
      Notification.create({:notification => "No torrents were found with the search term '#{movie.search_term}. <a href=\"#{link}\">Click here</a> to change your search term.", :sticky => true})
    end
  rescue Errno::ECONNRESET
    Notification.create(:notification => "The connection could not be made. Are you connected to the internet?")
  end

  def self.save_results(results, movie)
    results.each do |result|
      Download.create({:url => result.link, :download_name => result.name, :movie => movie, :status => Download::OPTIONAL})
    end
  end

end