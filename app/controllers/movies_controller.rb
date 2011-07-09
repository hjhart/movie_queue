class MoviesController < ApplicationController
  # GET /movies
  # GET /movies.json
  def list
    query = params[:q] || params[:term]
    @movies = Movie.get_movie_list(query)
    render json: @movies 
  end

  def get
    Movie.enqueue_all
  end

  def index
    @movies = []
    @movies << Movie.ready
    @movies << Movie.downloading.sort_by { |m| -(m.download.percent_done) }
    @movies << Movie.queued
    @movies = @movies.flatten
    ap @movies

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @movies }
    end
  end

  # GET /movies/1
  # GET /movies/1.json
  def show
    @movie = Movie.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @movie }
    end
  end

  # GET /movies/new
  # GET /movies/new.json
  def new
    @movie = Movie.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @movie }
    end
  end

  # GET /movies/1/edit
  def edit
    @movie = Movie.find(params[:id])
  end

  def download
    @movie = Movie.find(params[:id])
    Resque.enqueue(Movie, @movie.id)
    render :text => "Ok"
  end

  # POST /movies
  # POST /movies.json
  def create
    @movie = Movie.new(params[:movie])
    respond_to do |format|
      if @movie.save
        Resque.enqueue(Movie, @movie.id, params[:movie][:name])
        format.html { redirect_to edit_movie_url @movie }
      else
        format.html { render action: "new" }
      end
    end
  end

  # PUT /movies/1
  # PUT /movies/1.json
  def update
    @movie = Movie.find(params[:id])
    api_search_term = params[:movie][:name]

    puts "params --------------------------"
    ap params
    puts "api search term -----------------"
    puts api_search_term
    puts "params --------------------------"

    if(api_search_term)
      @movie.update_from_api(api_search_term)
      Notification.create(:notification => "Updated '#{@movie.search_term}' information using rotten tomatoes.")
    end

    respond_to do |format|
      if @movie.update_attributes(params[:movie])
        Resque.enqueue(Movie, @movie.id)
        format.html { redirect_to @movie, notice: 'Movie was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @movie.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /movies/1
  # DELETE /movies/1.json
  def destroy
    @movie = Movie.find(params[:id])
    @movie.destroy

    respond_to do |format|
      format.html { redirect_to movies_url }
      format.json { head :ok }
    end
  end


end
