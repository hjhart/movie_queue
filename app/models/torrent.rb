class Torrent

  @queue = 'torrent_queue'

  def self.perform(id)
    movie = Movie.find(id)
    if (movie.name)
      search = PirateBay::Search.new(movie.name)
      if results = search.execute
        puts "Received #{results.size} results from PirateBay"
        download_link = nil
        results.each do |result|
          if Movie.qualifies result
            download_link = result.link
            break
          end
        end
        if download_link
          puts "Found a qualifying torrent for #{movie} @ #{download_link}"
          d = Download.create(:url => download_link, :movie => movie, :status => Download::NEW)
          d.download
          movie.update_attributes({:download_start => true})
        else
          raise Exception.new("Retrieved search results, but none passed the requirements to download.")
        end
      else
        raise Exception.new("The search to pirate bay for #{movie.name} returned no results. Try again later (or change your qualification settings).")
      end
    end
  end

end