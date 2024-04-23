class TemperatureRecordsController < ApplicationController
  def search
    # Retrieve search parameters from the query string
    latitude = params[:latitude].to_f
    longitude = params[:longitude].to_f
    @longitude_search = longitude
    @latitude_search = latitude
    initial_radius = params[:initial_search_radius].to_i
    # combine date and time into one datetime object
    datetime = parse_datetime_from_params
    sort_merge = params[:sort_merge] == "1"
    sort_heap = params[:sort_heap] == "1"
    @developer = params[:developer] == "1"


    # Define these as per your requirements or make them configurable
    # increment_step = 1000 # Example: Increment by 1000 meters
    # max_radius = 20000 # Example: Maximum search radius

    # Use the model's method to perform the search
    # ========
    # DEBUGGING
    @records = TemperatureRecord.find_nearby_records(latitude, longitude, initial_radius = 2000, increment_step = 1000, max_radius = 2000000)
    @datetime = datetime

    @latitude_global = latitude
    @longitude_global = longitude
    # ========
    
    puts "Attempting to process records..."
    @filtered_records = TemperatureRecord.find_and_process_records(latitude, longitude, initial_radius, increment_step, max_radius, sort_merge, sort_heap, datetime)

    @average_temperature = average_temperature(@filtered_records)
    @average_temperature_f = (@average_temperature * 9 / 5 + 32).round(1)
    @confidence = calculate_confidence

    # @time_merge = benchmark_merge(@records)
    # @time_heap = benchmark_heap(@records)
  end

  def average_temperature(records)
    sum = 0
    for record in records do
      sum += record.outside_temp
    end
    sum = sum / records.length
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

  def calculate_confidence
    expected_total_records = 5000 # Set this based on your data knowledge
    max_date_diff = 30.days
    max_time_diff = 6.hours
    good_distance = 200000 # meters
    heavy_weight = 2 # adjust the weight for distance confidence
  
    nearby_ratio = @records.count.to_f / expected_total_records
    filtered_ratio = @filtered_records.count.to_f / @records.count
    date_confidence = 1 - (average_date_diff(@filtered_records) / max_date_diff)
    time_confidence = 1 - (average_time_diff(@filtered_records) / max_time_diff)
    
    # Calculate distance confidence based on a random record
    random_record = @filtered_records.sample
    distance_confidence = 1 - (record_distance_from_point(random_record) / good_distance)
  
    # Normalize the ratios to be between 0 and 1 for consistency
    nearby_ratio = normalize_ratio(nearby_ratio)
    filtered_ratio = normalize_ratio(filtered_ratio)
    distance_confidence = normalize_ratio(distance_confidence)
  
    # Calculate combined factors for confidence score (as a percentage), weighting distance heavily
    combined_factors = (nearby_ratio + filtered_ratio + date_confidence + time_confidence + distance_confidence * heavy_weight) / (4 + heavy_weight)
    confidence_percentage = (combined_factors * 100).round(2)
    
    # Ensure the percentage is within bounds
    [[confidence_percentage, 100].min, 0].max
  end
  
  private
  
  def record_distance_from_point(record)
    # Use the factory to create a point from the provided latitude and longitude
    target_point = RGeo::Geographic.spherical_factory(srid: 4326).point(@longitude_search.to_f, @latitude_search.to_f)
  
    # If you're using ActiveRecord and PostGIS adapter
    record.location.distance(target_point)
  end
    

  def normalize_ratio(ratio)
    [ratio, 1.0].min
  end

  def average_date_diff(records)
    total_days = records.reduce(0) do |sum, record|
      sum + (record.recorded_at.to_date - @datetime.to_date).abs
    end
    total_days / records.count
  end

  def average_time_diff(records)
    total_seconds = records.reduce(0) do |sum, record|
      sum + (record.recorded_at.seconds_since_midnight - @datetime.seconds_since_midnight).abs
    end
    total_seconds / records.count
  end
end
