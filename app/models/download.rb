require 'bencode'

class Download < ActiveRecord::Base
  NEW = 0
  OPENED = 1
  DOWNLOADING = 2
  COMPLETED = 3
  FAILED = 99

  belongs_to :movie
  @queue = :update_download_percent

  def self.perform()

    begin
      EventMachine.run do
#      Everytime we restart transmission we lose the uniqueness of tor.id
#      If we pause the torrent, the tor.startDate changes to be newer.
#      If we restart transmission we probably get a new startDate as well.

        t = Transmission::Client.new

        EM.add_periodic_timer(5) do
          t.torrents do |torrents|
            torrents.each do |tor|
              if (tor.eta > -1)
                download_range = (Time.at(tor.startDate) - 20.seconds)..(Time.at(tor.startDate) + 20.seconds)
                download = Download.where(:created_at => download_range)

                if (download.size == 0)
                  puts "The torrent was not found based on startDate. Searching by torrent_id: #{tor.id}"
                  download = Download.where(:torrent_id => tor.id, :status => Download::DOWNLOADING)
                  if (download.size == 1)
                    puts "The torrent was found based on torrent_id. Updated startDate."
                    d = download.first
                    d.created_at = Time.at(tor.startDate)
                    d.save!
                  end
                end

                if (download.size > 1)
                  raise "The downloads were performed too closely together, or your range is too wide. Debug at this point"
                elsif (download.size == 1)
                  download = download.first
                  download.percent_done = (tor.percentDone * 100).to_i
                  download.eta = tor.eta
                  download.status = Download::DOWNLOADING
                  download.torrent_id = tor.id
                  download.save!
                  puts "Updated attributes for #{tor.name} on Download #{download.id} #{download.download_name}"
                else
                  puts "No download found. :("
                end
              else
                "The torrent is complete. Do you want to remove it?"
              end
#         tor.status == 8 when seeding, methinks.
#          TODO: Option to remove torrent file when it's completed.'
            end
          end
        end

        t.on_download_finished do |torrent|
          download = Download.find_by_torrent_id(torrent.id)
          download.percent_done = 100
          download.eta = 0
          download.status = Download::COMPLETED
          download.torrent_id = -1
          download.save!
          puts "Completed download. Updated attributes for #{torrent.name} on Download #{download.id} #{download.download_name}"

          movie = download.movie
          movie.download_finish = true
          movie.save!

          # TODO: Integrate the movie renaming scheme on this directory

          t.remove(torrent.id)
        end

        t.on_torrent_stopped do |torrent|
          puts "Oooh torrent stopped"
        end

        t.on_torrent_started do |tor|
          puts "Torrent started."
          download_range = (90.seconds.ago)..(Time.now)
          download = Download.find_by_created_at(download_range)
          if download
            download.torrent_id = tor.id
            download.save!
            puts "Found a download, updating transmission ID. #{download.download_name}"
          else
            puts "Didn't find a download. Try again."
          end
        end

        t.on_torrent_removed do |torrent|
          puts "Darn torrent deleted."
          download = Download.find_by_torrent_id(torrent.id)
          if download
            puts "Found the deleted torrent. Deleteing appropriately."
            download.movie.delete
            download.delete
          else
            puts "Did not find the download by ID. Searching by started date."
            download_range = (Time.at(torrent.startDate) - 20.seconds)..(Time.at(torrent.startDate) + 20.seconds)
            download = Download.where(:created_at => download_range)
            if download
              puts "Found the deleted torrent by start date. Deleting appropriately."
              download.movie.delete
              download.delete
            end
          end
        end
      end
    rescue RuntimeError
      puts "Transmission is no longer open. Can we do anything?"
    end
  end

  def start_download(file)
    results = `open -a /Applications/Transmission.app #{file} 2>&1`
    if $?.success?
      self.status = Download::OPENED
      save!
    else
      self.status = Download::FAILED
      save!
      raise Exception.new("Error in #download for movie: '#{movie.name}'\n\nMessage:\ne#{results}")
    end
  end

  def store_file_data(file)

    open_file = File.open(file, 'rb')
    content = open_file.read
    decoded_torrent = BEncode.load(content)
    self.filesize = decoded_torrent["info"]["length"]
    self.hash = decoded_torrent["info"]["sha1"]
    self.download_name = decoded_torrent["info"]["name"]
    self.date_created = Time.at(decoded_torrent["creation date"].to_i)
    puts "Storing data into download: \nLength: #{self.filesize}\nHash:#{self.hash}\nDate Created#{self.date_created}"
    self.save!
    # TODO: FIgure out how to decode the crazy characters (/x0F)
  end

  def download
    # Download the file with wget or NEt:HTTP.
    # Open it somehow. Maybe with a shell command. Maybe with an API. You can't really...
    # TODO: Preference of which application you use.

    file = download_torrent_file
    store_file_data file
    start_download file
  end

  def download_torrent_file
    require 'open-uri'
    #TODO : Do this to a downloads directory or something

    file = File.join(Rails.root, "tmp", "tmp_torrent_#{DateTime.now.strftime('%s')}.torrent")
    writeOut = open(file, "wb")
    writeOut.write(open(self.url).read)
    writeOut.close

    file
  end

end
