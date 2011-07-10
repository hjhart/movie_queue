RAILS_ROOT = File.dirname(__FILE__)
RAILS_ENV = ENV["RAILS_ENV"]

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

