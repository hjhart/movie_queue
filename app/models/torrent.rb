class Torrent
  @queue = 'torrent_queue'

  def self.perform(id)

    movie = Movie.find(id)
    if (movie.name)
      search = PirateBay::Search.new(movie.name)
      if results = search.execute
        puts "Received #{results.size} results from PirateBay"
        download_result = nil
        results.each do |result|
          if Movie.qualifies result
            download_result = result
            break
          end
        end

        if download_result

          puts "Found a qualifying torrent for #{movie} @ #{download_result.link}"
          d = Download.create(:url => download_result.link, :movie => movie, :status => Download::DOWNLOADING, :download_name => download_result.name)
          d.download
          movie.update_attributes({:download_start => true})
          Notification.create({:notification => "The download for '#{d.download_name}' has begun.", :read => false})
        else
          save_results(results, movie)
          # perhaps we can use a better method of creating this link.
          link = "/movies/#{movie.id}/downloads"
          Notification.create({:notification => "No qualifying torrents were found. <a href=\"#{link}\">Click here</a> to manually select one of the results.", :read => false})
        end
      else
        raise Exception.new("The search to pirate bay for #{movie.name} returned no results. Try again later (or change your qualification settings).")
      end
    end
  end

  def self.save_results(results, movie)
    results.each do |result|
      Download.create({:url => result.link, :download_name => result.name, :movie => movie, :status => Download::OPTIONAL})
    end
  end
end