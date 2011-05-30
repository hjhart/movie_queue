class Download < ActiveRecord::Base
  NEW = 0
  OPENED = 1
  COMPLETED = 2
  FAILED = 99

  belongs_to :movie

  def download
    # Download the file with wget or NEt:HTTP.
    # Open it somehow. Maybe with a shell command. Maybe with an API. You can't really...
    # TODO: Preference of which application you use.

    file = download_torrent_file

    results = `open -a /Applications/uTorrent.app #{file} 2>&1`
    if $?.success?
      self.status = Download::OPENED
      save!
    else
      self.status = Download::FAILED
      save!
      raise Exception.new("Error in #download for movie: '#{movie.name}'\n\nMessage:\ne#{results}")
    end
  end

  def download_torrent_file
    require 'open-uri'

    file = File.join(Rails.root, "tmp", "tmp_torrent_#{DateTime.now.strftime('%s')}.torrent")
    writeOut = open(file, "wb")
    writeOut.write(open(self.url).read)
    writeOut.close

    file  
  end
end
