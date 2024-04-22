class TemperatureRecordsController < ApplicationController
  def search
    # Retrieve search parameters from the query string
    latitude = params[:latitude].to_f
    longitude = params[:longitude].to_f
    initial_radius = params[:initial_search_radius].to_i
    # combine date and time into one datetime object
    datetime = parse_datetime_from_params
    sort_merge = params[:sort_merge] == "1"
    sort_heap = params[:sort_heap] == "1"


    # Define these as per your requirements or make them configurable
    # increment_step = 1000 # Example: Increment by 1000 meters
    # max_radius = 20000 # Example: Maximum search radius

    # Use the model's method to perform the search
    # ========
    # DEBUGGING
    @records = TemperatureRecord.find_nearby_records(latitude, longitude, initial_radius)
    @datetime = datetime

    @latitude_global = latitude
    @longitude_global = longitude
    # ========
    
    puts "Attempting to process records..."
    @filtered_records = TemperatureRecord.find_and_process_records(latitude, longitude, initial_radius = 2000, increment_step = 1000, max_radius = 2000000, datetime, sort_merge, sort_heap)
  end

  def parse_datetime_from_params
    date_str = params[:date]
    time_str = params[:time]
  
    begin
      # If both date and time parameters are present, attempt to parse them into a datetime
      if date_str.present? && time_str.present?
        datetime = "#{date_str} #{time_str}".to_datetime
      else
        # If either date or time is missing, default to the current datetime
        datetime = DateTime.current
      end
    rescue ArgumentError => e
      # If there's an error parsing the date or time, default to the current datetime
      puts "Error parsing datetime, defaulting to current: #{e.message}"
      datetime = DateTime.current
    end
  
    datetime
  end
end
