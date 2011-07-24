require 'yaml'
require 'active_record'
require 'rottentomatoes'
require 'ap'

require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'app', 'models', 'download')
require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'app', 'models', 'movie')
require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'app', 'models', 'notification')
require 'transmission-client'

RAILS_ENV = ENV['RAILS_ENV'] ||= 'development'
dbconfig = YAML::load(File.open(File.join(File.expand_path(File.dirname(__FILE__)), '..', 'config', 'database.yml')))[RAILS_ENV]
puts dbconfig
ActiveRecord::Base.establish_connection(dbconfig)

begin

  EventMachine.run do
    t = Transmission::Client.new

    EM.add_periodic_timer(3) do
#      Get hashes and remove the stale downloading movies.
#      
      t.torrents do |torrents|
        ap t

        downloading_hashes = []

        torrents.each do |torrent|
          downloading_hashes.push(torrent.hashString)
        end

        stopped = []

        Movie.downloading.each do |movie|
          if(!downloading_hashes.include? movie.download.hash)
            stopped << movie.search_term
            movie.download_start = nil
            movie.save
            download = movie.download
            download.eta = nil
            download.download_location = File.join(torrent.downloadDir, torrent.name)
            download.status = Download::OPENED
            download.percent_done = 0
            download.save
          end
        end

        

        if(stopped.size > 0)
          notification =  "#{stopped.size} downloads have stopped. Updated their records. (#{stopped.join(',')})"
          puts  notification
          Notification.create(:notification => notification, :sticky => true)
        end
      end
    end

    EM.add_periodic_timer(5) do
      t.torrents do |torrents|
        torrents.each do |torrent|
          download = Download.find_by_hash(torrent.hashString)
          if (download)
            download_status = torrent.doneDate.to_i > 0 ? Download::COMPLETED : Download::DOWNLOADING
            download.percent_done = (torrent.percentDone * 100).to_i
            download.eta = torrent.eta
            download.status = download_status
            download.save!
          end
        end
      end
    end

    t.on_download_finished do |torrent|
      Notification.create(:notification => "Torrent completed! #{torrent.name}", :sticky => true)
      download = Download.find_by_hash(torrent.hash)
      if (download)
        download.percent_done = 100
        download.eta = 0
        download.status = Download::COMPLETED
        download.save!
        movie = download.movie
        movie.download_finish = true
        movie.save!

        # TODO: Integrate the movie renaming scheme on this directory
      end

    end

    t.on_torrent_removed do |torrent|
      Notification.create(:notification => "The torrent was removed from transmission: #{torrent.name}")
      if (torrent.doneDate.to_i > 0) # If the torrent finished, it will be in the present.
        puts "The torrent was already done for #{torrent.name}. Not deleting from records."
      else
        download = Download.find_by_hash(torrent.hashString)
        if download
          puts "Found the deleted torrent. Deleteing appropriately."
#            download.movie.delete
#            download.delete
#            TODO: The deleting of a record is currently disabled.
        end
      end

    end
  end
rescue RuntimeError
  Notification.create(:notification => "Cannot communicate with Transmission. Is it open?")
  puts "Transmission is no longer open. Can we do anything?"
end