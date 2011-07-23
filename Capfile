
set :user, "james"
set :runner, user
set :server_name, "home"


set :use_sudo, false
set :application, "movie_queue"
set :repository, "git@github.com:hjhart/humho.git"
set :scm, 'git'
set :deploy_via, :remote_cache
set :deploy_to, "/Users/james/Sites/movie_queue"
set :scm_command, "/usr/local/bin/git"

set :server, "home"
set :use_sqlite3, true


ssh_options[:forward_agent] = true

load 'deploy'

role :web, server_name.to_s
role :app, server_name.to_s
role :db, server_name.to_s

# Paths
set :shared_database_path,        "#{shared_path}/databases"
set :shared_config_path,          "#{shared_path}/config"


namespace :sqlite3 do

  desc "Generate a database configuration file"
  task :build_configuration, :roles => :db do
    db_options = {
      "adapter"  => "sqlite3",
      "database" => "db/production.sqlite3"
    }
    config_options = {"production" => db_options}.to_yaml
    put config_options, "#{shared_config_path}/sqlite_config.yml"
  end

  desc "Links the configuration file"
  task :link_configuration_file, :roles => :db do
    run "ln -nsf #{shared_config_path}/sqlite_config.yml #{current_path}/config/database.yml"
    run "touch #{shared_database_path}/production.sqlite3"
    run "ln -nsf #{shared_database_path}/production.sqlite3 #{current_path}/db/production.sqlite3"
  end

  desc "Make a shared database folder"
  task :make_shared_folder, :roles => :db do
    run "mkdir -p #{shared_database_path}"
  end

end

if use_sqlite3
  after "deploy:setup", "sqlite3:make_shared_folder"
  after "deploy:setup", "sqlite3:build_configuration"
  after "deploy:symlink", "sqlite3:link_configuration_file"
end


namespace :deploy do
  desc "Restarting mod_rails with restart.txt"
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{current_path}/tmp/restart.txt"
  end

   [:start, :stop].each do |t|
    desc "#{t} task is a no-op with mod_rails"
    task t, :roles => :app do ; end
  end
end