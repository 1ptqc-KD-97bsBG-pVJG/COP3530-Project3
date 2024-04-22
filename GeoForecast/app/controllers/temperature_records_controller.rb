class TemperatureRecordsController < ApplicationController
  def search
    # Retrieve search parameters from the query string
    latitude = params[:latitude].to_f
    longitude = params[:longitude].to_f
    initial_radius = params[:initial_search_radius].to_i

    # Define these as per your requirements or make them configurable
    # increment_step = 1000 # Example: Increment by 1000 meters
    # max_radius = 20000 # Example: Maximum search radius

    # Use the model's method to perform the search
    @records = TemperatureRecord.find_nearby_records(latitude, longitude, initial_radius)

    @latitude_global = latitude
    @longitude_global = longitude
    # Render a view to display the search results (you'll need to create this view)
    # If you're going to use the same view ('home/index'), you can redirect or simply render 'home/index'
  end
end
