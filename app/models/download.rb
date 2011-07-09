require 'bencode'

class Download < ActiveRecord::Base
  NEW = 0
  OPENED = 1
  DOWNLOADING = 2
  COMPLETED = 3
  OPTIONAL = 98
  FAILED = 99

  belongs_to :movie

  @queue = :update_download_percent

  def self.perform()
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
    require 'digest/sha1'

    open_file = File.open(file, 'rb')
    content = open_file.read
    decoded_torrent = BEncode.load(content)

    puts "-====- " * 30
    puts "Encoding torrent hash:"
    puts decoded_torrent["info"].bencode
    puts "-====- " * 30

    self.filesize = decoded_torrent["info"]["length"]
    self.hash = Digest::SHA1.hexdigest(decoded_torrent["info"].bencode)
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
