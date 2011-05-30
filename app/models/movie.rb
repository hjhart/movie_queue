require 'rubygems'
require 'pirate_bay'

class Movie < ActiveRecord::Base

  MINIMUM_SEEDS = 10
  MAX_FILE_SIZE = 1000000000 # in bytes
  MIN_FILE_SIZE = 400000000

  def self.qualifies(result)
    # TODO: Specifying categories?

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

  def self.unqueued
    Movie.all(:conditions => {:download_start => false})
  end

  def eligible_files
    movie = Movie.find(id)
    if (movie.name)
      search = PirateBay::Search.new(movie.name)
      if results = search.execute
        filtered_results = results.select { |r| Movie.qualifies r }
      end
    end
    filtered_results
  end

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
          d = Download.create(:url => download_link, :movie => movie, :status => Download::NEW)
          d.download
          movie.update_attributes({:download_start => true})
        else
          raise Exception.new("Retrieved search results, but none passed the requirements to download.")
        end
      else
        raise Exception.new("The search to pirate bay for #{movie.name} returned no results. Try again later.")
      end
    end
  end

  def self.enqueue_all
    Movie.unqueued.each do |movie|
      Movie.perform(movie.id)
    end
  end

  def self.get_movie_list(movie_name)
    include RottenTomatoes

    Rotten.api_key = 'z2s2hk9pm7zw3zubd5mrbk2m'
    movies = RottenMovie.find(:title => movie_name, :limit => 10)
    movies.map {|movie| "#{movie.title} (#{movie.year})" }
  end
end
