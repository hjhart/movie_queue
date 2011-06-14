# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20110609070722) do

  create_table "downloads", :force => true do |t|
    t.string   "url"
    t.integer  "movie_id"
    t.integer  "status"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "percent_done"
    t.integer  "filesize"
    t.datetime "date_created"
    t.string   "download_name"
    t.string   "hash"
    t.integer  "eta"
    t.integer  "torrent_id"
  end

  create_table "movies", :force => true do |t|
    t.string   "name"
    t.boolean  "active"
    t.boolean  "download_start"
    t.boolean  "download_finish"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.date     "dvd_release_date"
    t.string   "year"
    t.string   "mpaa_rating"
    t.string   "thumbnail_url"
    t.string   "url"
    t.integer  "audience_score"
    t.integer  "critics_score"
    t.integer  "runtime"
    t.string   "search_term"
  end

end
