Movie Queue
===========

### Disclaimer

This is an ALPHA release. I'd love to help other people get set up, so if you have any problems _please_ feel free to email me or message me on github. 

Reach me at : hjhart [at] gmail [dot] com

## Purpose

MovieQueue is an ad-free, no-maintenance, webserver whose sole purpose is downloading movies you want to watch.  It queries multiple bittorrent websites and brings search results back to the web interface so you can pick the best one to download. You can add a movie from anywhere you can find a web browser, and come home later only to find your movie is ready to watch! Cool, huh?

## Screenshots

Cover Art UI with tooltips

![MovieQueue - Home Page UI](http://farm7.static.flickr.com/6121/5972429264_e40bbbf61e_z.jpg "MovieQueue - Home Page UI")

Check a movies download progress and Estimated Time Arrival. You can also see meta-data provided by RottenTomatoes.

![MovieQueue - Info Tooltip](http://farm7.static.flickr.com/6145/5972428962_3371430ff0_z.jpg "MovieQueue - Info Tooltip")

Add A Movie dialogue

![MovieQueue - Add a Movie](http://farm7.static.flickr.com/6010/5972429086_247d3ef0b7_z.jpg "MovieQueue - Add a Movie UI")


## Features

- Plugs into RottenTomatoes to retrieve movie metadata
- Queries multiple torrent sites – The Pirate Bay, Demonoid, and TorrentReactor – to pull in search results.
- Track all of your downloads statuses from any web browser.
- Easy to read tooltips for each movie for more detailed information.
- Easy setup - A lightweight [god](http://god.rubyforge.org/ "god") ruby script that will watch and keep side-processes running.
- Talks to [Transmission](http://www.transmissionbt.com/ "transmission") bittorrent client to retrieve your downloads statuses.
- Automatic downloading of a movie without having to select a torrent (coming soon)
- Robust notification system.
- Simple UI and an efficient UX 
- Add movies from work, have them ready to watch when you get home!


## Installation

#### Check your prerequisites

Note: If you don't have redis, postgres, and transmission, please refer farther down to get them installed.

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

Follow the post-install instructions to start it.

### Transmission

I've set up a method of talking to transmission, but some preferences need to be tweaked to optimize the workflow.
I'm using version 2.3.2 of transmission currently.


0. Open up transmission
1. Open your preferences.
2. Under the "Remote" tab: Check the checkbox "Enable Remote Access". Uncheck "Require Authentication".
This will allow a side-process to talk to both transmission and update records in the database.
3. Under the "Transfers" tab, "Management" subtab: Uncheck the "Display a window when opening a torrent file"
This will make additions of torrents into your server more fluid.

### PostgreSQL

I tried this with a Sqlite3 database and had plenty of problems, so I've settled with postgres for now. I imagine this would work fine with a mysql install as well (can anyone confirm?). If you don't have postgres already installed you can install it using homebrew

    brew install postgres

Follow the post-install instructions to start it. Now you can go configure your database (as 

## Todo

- Drag and drop movie suggestions. Have a column of movies on the right, drag them to the queue to begin a download.
- Get the server working with capistrano/passenger
- Add better notifications (perhaps without a poll method and a direct subscription [with redis])
- Grabs RSS feeds automatically and downloads movies automatically. (Like, from new arrivals, whose category is Action and whose metascore is greater than 88)
- Stream movies directly from the web-browser. Watch anywhere. (A huge one on my wishlist. Movie streaming is not my forte. Anyone want to help?)
- A mobile optimized site 
- An autocompleter for the movie (as you're typing in the add dialogue)
- Determine whether the movies added are available on instant watches such as Amazon Insant or Netflix Streaming. Provide the link to watch it streaming.
- Integration DataTables js into multiple tables in order to get sortable/filterable tables.
- Renaming the movie and dropping it into your media collection.
- Torrent preferences on filesize and types of rips to download .

http://developer.netflix.com/docs/read/Common_Tasks#0_51188 (has an autocompleter built in to it)
Netflix / Amazon Instant streaming detection

### Notes

- Tested with ruby-1.9.2, rvm, osx 10.6, macbook pro.

