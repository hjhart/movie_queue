# TODO: IS it possible to download the files from tpb that have square braackets? URI.parse doesn't work with 'em.
# TODO: Consider 404 messages from TPB
# TODO: TPB gem should only be searching for movies
# TODO: Can we implement music for this as well?
# TODO: Integrated torrent application using ruby-torrent
# TODO: Streaming via ffmpeg
# TODO: Notifications that a resque queue completed but failed. "Push notifications"

require 'rubygems'
require 'pirate_bay'

class Movie < ActiveRecord::Base

  @queue = 'movie_queue'

  scope :queued, :conditions => {:download_start => nil}
  scope :ready, :conditions => {:download_start => true, :download_finish => true}
  scope :downloading, :conditions => {:download_start => true, :download_finish => nil}

  has_many :downloads
  
  MINIMUM_SEEDS = 5
  MAX_FILE_SIZE = 1000000000 # in bytes
  MIN_FILE_SIZE = 400000000

  def queue_date
    return "(In Theatres)" if self.dvd_release_date.nil?
    return "(#{self.year})" if (Date.today > self.dvd_release_date)
    return "(Comes out #{self.dvd_release_date})" if self.dvd_release_date
  end

  def self.qualifies(result)
    # TODO: Specifying categories?
    # TODO: Delayed queue - add movies to queue.

    # check min seeds
    if result.seeds < MINIMUM_SEEDS
      puts "Torrent didn't have enough seeds: #{result.seeds}"
      return false
    end

    # check filesize
    filesize = Movie.filesize_in_bytes result.size
    if filesize > MAX_FILE_SIZE || filesize < MIN_FILE_SIZE
      puts "File was either too big or too small: #{result.size}"
      return false
    end

    # check filename to see if it's parsable
    begin
      URI.parse(result.link)
    rescue
      puts "The URL was unparsable, so we're skipping it. #{result.link}"
      return false
    end

    true
  end

  def percent_complete
    percent = downloads.first.percent_done
    return 0 if percent.nil?
    percent
  end

  def display_eta
    eta = downloads.first.eta
    return nil if(eta.nil?)
    eta_in_seconds = eta.to_i

    display_eta = case
      when eta_in_seconds == -1
        "Done"
      when eta_in_seconds < 60
        "< 1 min"
      when eta_in_seconds > 60 && eta_in_seconds < 3600
        "#{(eta_in_seconds / 60).to_i} mins"
      when eta_in_seconds
        "#{(eta_in_seconds / 3600).to_i} hr #{(eta_in_seconds / 60) % 60} mins"
      else
        "n/a"
    end
  end

  def self.perform(id)
    movie = Movie.find(id)
    include RottenTomatoes
    Rotten.api_key = 'z2s2hk9pm7zw3zubd5mrbk2m'

    puts "Searching Rotten Tomatoes API for movie #{movie.search_term}"

    result = RottenMovie.find(:title => movie.search_term, :expand_results => true, :limit => 1)

    if result
      ap result
      release_date = result.release_dates.dvd

      puts "Received results for movie #{result.title}"
      movie.update_attributes({
         :name => result.title,
         :dvd_release_date => result.release_dates.dvd,
         :year => result.year,
         :mpaa_rating => result.mpaa_rating,
         :thumbnail_url => result.posters.detailed,
         :url => result.links.alternate,
         :audience_score => result.ratings.audience_score,
         :critics_score => result.ratings.critics_score,
         :runtime => result.runtime,
      })

      if(release_date)

        if (Date.today + 1.week) > Date.parse(release_date) # movies are usually released a little bit ahead of their time
          Resque.enqueue(Torrent, id)
          puts "Enqueued the torrent"
        else
          puts "The movie hasn't been released yet. Will not enqueue the download."
          # TODO: Figure out how to enqueue this one. Schedule it on a date. Or just every night at midnight.
        end
      else
        puts "The movie didn't have a DVD release date listed. It's probably still in theatres."
      end
    else
      puts "No results were found from Rotten Tomato API."
    end

  end

  def self.filesize_in_bytes(filesize)
    match = filesize.match(/([\d.]+)(.*)/i)
    if match
      raw_size = match[1].to_f

      case match[2].strip
        when /GiB/i then
          raw_size * 1000000000
        when /MiB/i then
          raw_size * 1000000
        when /KiB/i then
          raw_size * 1000
        else
          nil
      end
    else
      nil
    end

  end

  def eligible_files
    movie = Movie.find(id)
    if (movie.name)
      search = PirateBay::Search.new(movie.search_term)
      if results = search.execute
        filtered_results = results.select { |r| Movie.qualifies r }
      end
    end
    filtered_results
  end


  def self.enqueue_all
    Movie.queued.each do |movie|
      Movie.perform(movie.id)
    end
  end

  def self.get_movie_list(movie_name)
    include RottenTomatoes

    Rotten.api_key = 'z2s2hk9pm7zw3zubd5mrbk2m'
    movies = RottenMovie.find(:title => movie_name, :limit => 10)
    movies.map { |movie| "#{movie.title} (#{movie.year})" }
  end
end
