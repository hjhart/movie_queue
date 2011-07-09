# TODO: IS it possible to download the files from tpb that have square braackets? URI.parse doesn't work with 'em.
# TODO: Consider 404 messages from TPB
# TODO: TPB gem should only be searching for movies
# TODO: Can we implement music for this as well?
# TODO: Integrated torrent application using ruby-torrent
# TODO: Streaming via ffmpeg
# TODO: Notifications that a resque queue completed but failed. "Push notifications"

require 'rubygems'
require 'pirate_bay'
include RottenTomatoes

class Movie < ActiveRecord::Base

  @queue = 'movie_queue'

  scope :queued, :conditions => {:download_start => nil}
  scope :ready, :conditions => {:download_start => true, :download_finish => true}
  scope :downloading, :conditions => {:download_start => true, :download_finish => nil}

  has_one :download
  has_many :torrents

  MINIMUM_SEEDS = 5
  MAX_FILE_SIZE = 1000000000 # in bytes
  MIN_FILE_SIZE = 400000000

  def queue_date
    return "Loading..." if self.api_queried.nil?
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
    filesize = result.size.to_i
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
    if self.download.nil?
      return ""
    end
    if self.download_finish? || (self.download.eta != nil && self.download.eta <= 0)
      return ""
    end
    eta = download.eta
    return nil if (eta.nil?)
    eta_in_seconds = eta.to_i

    seconds_to_string(eta_in_seconds)
  end

  def seconds_to_string(seconds)
    case
      when seconds == 0
        "Done"
      when seconds < 60
        "< 1 min"
      when seconds > 60 && seconds < 3600
        "#{(seconds / 60).to_i} mins"
      when seconds >= 3600
        "#{(seconds / 3600).to_i} hr #{(seconds / 60) % 60} mins"
      else
        "n/a"
    end
  end

  def movie_cover_path
    if api_queried.nil?
      "loading_cover.png"
    elsif thumbnail_url.nil?
      "no_cover.png"
    else
      thumbnail_url
    end
  end

  def update_from_api(search_term=self.search_term)
    puts "Searching for #{search_term}"

    Rotten.api_key = 'z2s2hk9pm7zw3zubd5mrbk2m'

    result = RottenMovie.find(:title => search_term, :limit => 1)

    update_attributes({
                          :name => result.title,
                          :dvd_release_date => result.release_dates.dvd,
                          :year => result.year,
                          :mpaa_rating => result.mpaa_rating,
                          :thumbnail_url => result.posters.detailed,
                          :url => result.links.alternate,
                          :audience_score => result.ratings.audience_score,
                          :critics_score => result.ratings.critics_score,
                          :runtime => result.runtime,
                          :api_queried => true
                      })
  end

  def self.perform(id, search_term=nil, auto_download=false)
    movie = Movie.find(id)

    unless movie.api_queried

      include RottenTomatoes
      Rotten.api_key = 'z2s2hk9pm7zw3zubd5mrbk2m'

      unless search_term
        search_term = movie.search_term
      end

      Notification.create(:notification => "Searching rotten tomatoes for '#{search_term}'")
      puts "Searching Rotten Tomatoes API for movie #{search_term}"

      if (search_term)
        movie.update_from_api(search_term)
        Notification.create(:notification => "Updated '#{search_term}' information using rotten tomatoes.")
      end
    end

    if (movie.dvd_release_date)
      if (Date.today + 1.week) > movie.dvd_release_date # movies are usually released a little bit ahead of their time
        Resque.enqueue(Torrent, id) if auto_download
        puts "Enqueued the torrent"
      else
        puts "The movie hasn't been released yet. Will not enqueue the download."
        Notification.create(:notification => "The movie '#{movie.search_term}' is not available on DVD yet, and is not downloading.")
        # TODO: Figure out how to enqueue this one. Schedule it on a date. Or just every night at midnight.
      end
    else
      puts "The movie didn't have a DVD release date listed. It's probably still in theatres."
      Notification.create(:notification => "The movie '#{movie.search_term}' is still in theatres and is not downloading.")
    end


  rescue Errno::ECONNRESET
    Notification.create(:notification => "The connection could not be made. Are you connected to the internet?")
  end

  def self.filesize_in_bytes(filesize)
    match = filesize.match(/([\d.]+)(.*)/)

    if match
      raw_size = match[1].to_f

      case match[2].strip
        when /gib/i then
          raw_size * 1000000000
        when /mib/i then
          raw_size * 1000000
        when /kib/i then
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

  def image_percentage_height
    if download.nil?
      return "250px"
    end

    if download.percent_done.nil?
      return "250px"
    end

    total_height = 250
    "#{(1.0 - (download.percent_done / 100.0)) * total_height}px"
  end

  def fetch_and_save_torrents(search_term)
    Resque.enqueue(Torrent, self.id, search_term, :all, false)
  end
end
