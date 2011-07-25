Movie Queue
===========

### Disclaimer

This is an ALPHA release. I'd love to help other people get set up, so if you have any problems _please_ feel free to email me or message me on github. 

Reach me at : hjhart [at] gmail [dot] com

## Purpose

MovieQueue is an ad-free, stress-free, accessible-anywhere server whose sole purpose is downloading movies that YOU want to watch. It queries multiple torrent websites to search for movie torrents and brings them back to the easy-to-use web interface so you can download the best torrent for your needs. 

## Screenshots

Cover Art UI with tooltips

![MovieQueue - Home Page UI](http://farm7.static.flickr.com/6121/5972429264_e40bbbf61e_z.jpg "MovieQueue - Home Page UI")

Check a movies download progress and Estimated Time Arrival. You can also see meta-data provided by RottenTomatoes.

![MovieQueue - Info Tooltip](http://farm7.static.flickr.com/6145/5972428962_3371430ff0_z.jpg "MovieQueue - Info Tooltip")

Add A Movie dialogue

![MovieQueue - Add a Movie](http://farm7.static.flickr.com/6010/5972429086_247d3ef0b7_z.jpg "MovieQueue - Add a Movie UI")


## Features

- Plugs into RottenTomatoes for the meta data (coverart, metacritic score, rottentomatoes score, runtime, mpaa rating, link to RT to watch trailers)
- Plugs into The Pirate Bay, Demonoid, and TorrentReactor to pull in search results
- Know when your download is scheduled to finish and what percentage is done
- Robust notification system that lets you know when downloads finish.
- Remarkably simple method of adding new movies to the queue.
- Simple UI with only a display of the movie cover art.
- Easy to read tooltips for each movie for more detailed information on the homepage.
- "God" support that will watch resque workers and communicate with transmission
- Transmission communicator updates download progress for each individual torrent.
- Automatic downloading of movies without having to select a torrent (coming soon)
- Torrent preferences on filesize and types of rips to download (coming soon)
- Web server accessible from anywhere will allow you to add movies on the go!
- Streaming the movie directly from the browser (A big wishlist. Movie streaming is not my forte. Anyone want to help?)
- Renaming the movie and dropping it into your media collection. (coming soon)

## Installation

### Check your prerequisites

If you don't have redis, postgres, and transmission, please refer farther down to get them installed.

### Clone and bundle

    cd ~/Sites # or wherever you want the server to live
    git clone git@github.com:hjhart/movie_queue.git movie_queue
    cd movie_queue
    gem install bundler # if you don't already have it
    bundle # short for bundle install, this will grab all of the dependencies

### Set up database

Make a copy of config/database.template.yml to config/database.yml.
Edit config/database.yml to be compatible with your installation of postgres.

    RAILS_ENV=production rake db:setup # Set up the database, perform migrations with:

### Set up God

Now that you've got the code and the dependencies, we should be able to start up the side-processes. I've made it fairly easy to do so by setting up a god process.

    RAILS_ENV=production god -c application.god -D

I'd sit around and watch this process for a while to make sure that resque starts as well as the transmission watcher. Output will begin to look like this:

    I [2011-07-24 16:17:30]  INFO: transmission-watcher [ok] process is running (ProcessRunning)
    I [2011-07-24 16:17:43]  INFO: resque-1.8.0 [ok] memory within bounds [792kb, 792kb] (MemoryUsage)
    I [2011-07-24 16:17:56]  INFO: resque-1.8.0 [ok] process is running (ProcessRunning)

### Start the server

    RAILS_ENV=production rails s

Now point your browser to localhost:3000 and everything should be up and running. :)

This is an ALPHA release. It works great on my server but I'm sure there will be compatibility issues as soon as someone else sets it up. Please get ahold of me if/when you have problems. I'd love to get feedback for this as well.

---

## Prerequisites

MovieQueue has a few prerequisites before you can get started.

- Redis
- Transmission (with adjusted settings)
- PostgreSQL

### Redis

If you haven't installed redis, you can do so using homebrew

    brew install redis

### Transmission

I've set up a method of talking to transmission, but steps need to be taken in order to "plug in".
I'm using version 2.3.2 of transmission currently.


0. Open up transmission
1. Open your preferences.
2. Under the "Remote" tab: Check the checkbox "Enable Remote Access". Uncheck "Require Authentication".
This will allow a side-process to talk to both transmission and update records in the database.
3. Under the "Transfers" tab, "Management" subtab: Uncheck the "Display a window when opening a torrent file"
This will make additions of torrents into your server more fluid.

### PostgreSQL

I tried this with a Sqlite3 database and had plenty of problems. If you don't have postgres already installed you can install it using homebrew

    brew install postgres

Follow the post-install instructions to start it.

## Todo

- Get the server working with capistrano/passenger
- Add better notifications (perhaps without a poll method and a direct subscription [with redis])
- Grabs RSS feeds automatically and downloads movies automatically. (Like, from new arrivals, whose category is Action and whose metascore is greater than 88)
- Stream movies directly from the web-browser. Watch anywhere.
- A mobile optimized site 
- An autocompleter for the movie (as you're typing in the add dialogue)
- Determine whether the movies added are available on instant watches such as Amazon Insant or Netflix Streaming. Provide the link to watch it streaming.
- Integration DataTables js into multiple tables in order to get sortable/filterable tables.

http://developer.netflix.com/docs/read/Common_Tasks#0_51188 (has an autocompleter built in to it)
Netflix / Amazon Instant streaming detection

### Notes

- Tested with ruby-1.9.2, rvm, osx 10.6, macbook pro.

