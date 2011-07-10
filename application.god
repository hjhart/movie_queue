RAILS_ROOT = "/Users/jhart/Sites/movie_queue"

#God.watch do |w|
#  port = 3001
#  w.name = "movie_queue_server"
#  w.interval = 30.seconds # default
#  w.start = "cd #{RAILS_ROOT} && rails server"
#  w.start_grace = 10.seconds
#  w.pid_file = File.join(RAILS_ROOT, "log/mongrel.#{port}.pid")
#
#  w.behavior(:clean_pid_file)
#
#  w.start_if do |start|
#    start.condition(:process_running) do |c|
#      c.interval = 5.seconds
#      c.running = false
#    end
#  end
#
#  w.restart_if do |restart|
#    restart.condition(:memory_usage) do |c|
#      c.above = 150.megabytes
#      c.times = [3, 5] # 3 out of 5 intervals
#    end
#
#    restart.condition(:cpu_usage) do |c|
#      c.above = 50.percent
#      c.times = 5
#    end
#  end
#
##  lifecycle
#  w.lifecycle do |on|
#    on.condition(:flapping) do |c|
#      c.to_state = [:start, :restart]
#      c.times = 5
#      c.within = 5.minute
#      c.transition = :unmonitored
#      c.retry_in = 10.minutes
#      c.retry_times = 5
#      c.retry_within = 2.hours
#    end
#  end
#end

# Redis
God.watch do |w|
  w.name = "redis"
  w.interval = 30.seconds
  w.start = "/usr/local/bin/redis-server /usr/local/etc/redis.conf"
  w.start_grace = 10.seconds
  w.restart_grace = 10.seconds

  w.start_if do |start|
    start.condition(:process_running) do |c|
      c.interval = 5.seconds
      c.running = false
    end
  end
end

# Transmission talker
God.watch do |w|
  w.name = "transmission-watcher"
  w.interval = 30.seconds
  w.start = "cd #{RAILS_ROOT} && ruby lib/transmission_watch.rb"
  w.start_grace = 10.seconds
  w.restart_grace = 10.seconds

  w.start_if do |start|
    start.condition(:process_running) do |c|
      c.interval = 30.seconds
      c.running = false
    end
  end
end

# Resque
God.watch do |w|
  w.name = "resque-1.8.0"
  w.interval = 30.seconds
  w.start = "cd #{RAILS_ROOT} && rake environment resque:work QUEUE=*"
  w.start_grace = 10.seconds

  # retart if memory gets too high
  w.transition(:up, :restart) do |on|
    on.condition(:memory_usage) do |c|
      c.above = 350.megabytes
      c.times = 2
    end
  end

  # determine the state on startup
  w.transition(:init, {true => :up, false => :start}) do |on|
    on.condition(:process_running) do |c|
      c.running = true
    end
  end

  # determine when process has finished starting
  w.transition([:start, :restart], :up) do |on|
    on.condition(:process_running) do |c|
      c.running = true
      c.interval = 5.seconds
    end

    # failsafe
    on.condition(:tries) do |c|
      c.times = 5
      c.transition = :start
      c.interval = 5.seconds
    end
  end

  # start if process is not running
  w.transition(:up, :start) do |on|
    on.condition(:process_running) do |c|
      c.running = false
    end
  end
end

