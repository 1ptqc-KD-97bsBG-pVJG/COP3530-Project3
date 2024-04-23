require 'benchmark'
class TemperatureRecord < ApplicationRecord
  def self.find_and_process_records(latitude, longitude, initial_radius = 2000, increment_step = 1000, max_radius = 2000000, sort_merge = false, sort_heap = true, datetime)
     records = find_nearby_records(latitude, longitude, initial_radius, increment_step, max_radius)
     sorted_records = process_sorting(records, sort_merge, sort_heap)
     filtered_records = filter_records(sorted_records, datetime)

    filtered_records
  end

  # Method to find records within a specified radius around a point
  # If no records are found in the initial search, it will expand the search radius incrementally
  # If records are found after expanding the radius, it will further expand the radius by 2000 meters to capture nearby records
  
  # max_radius set to approximately furthest point on continental US from data
  def self.find_nearby_records(latitude, longitude, initial_radius, increment_step, max_radius)
    #PostGIS functions and queries 
    location_point = RGeo::Geographic.spherical_factory(srid: 4326).point(longitude, latitude)
    radius = initial_radius
    records = where("ST_DWithin(location, ST_SetSRID(ST_MakePoint(?, ?), 4326), ?)", longitude, latitude, radius)
              .order(Arel.sql("ST_Distance(location, ST_SetSRID(ST_MakePoint(#{longitude}, #{latitude}), 4326))"))
    # Flag to check if radius was ever incremented
    radius_incremented = false

    # If no records are found in the initial search, increment the radius until found or reaches max
    while records.none? && radius <= max_radius
      radius += increment_step
      radius_incremented = true
      records = where("ST_DWithin(location, ST_SetSRID(ST_MakePoint(?, ?), 4326), ?)", longitude, latitude, radius)
              .order(Arel.sql("ST_Distance(location, ST_SetSRID(ST_MakePoint(#{longitude}, #{latitude}), 4326))"))

      end

      # If records are found after incrementing, and radius can be further expanded by 2000 meters, do so to neighboring records
      if records.any? && radius_incremented && (radius + 2000) <= max_radius
        radius += 2000
        records = where("ST_DWithin(location, ST_SetSRID(ST_MakePoint(?, ?), 4326), ?)", longitude, latitude, radius)
                .order(Arel.sql("ST_Distance(location, ST_SetSRID(ST_MakePoint(#{longitude}, #{latitude}), 4326))"))
      end

    records
   end

  def self.process_sorting(records, sort_merge, sort_heap)
    sorted_records = records
    if sort_merge
      puts "Sorting records with merge sort..."
      time = Benchmark.realtime do
        sorted_records =  merge_sort(records)
      end
      puts "Merge sort took #{time.round(8)*1000} milliseconds"
      begin
      rescue => e
        puts "Error sorting records with merge sort: #{e.message}"
      end
    end

    if sort_heap
      puts "Sorting records with heap sort..."
      time = Benchmark.realtime do
          sorted_records =  heap_sort(records)
      end
      puts "Heap sort took #{time.round(8)*1000} milliseconds"
      begin
      rescue => e
        puts "Error sorting records with heap sort: #{e.message}"
      end
    end

    sorted_records
  end

  def self.benchmark_heap(records) 
    time_heap = Benchmark.realtime do
      sorted_records =  heap_sort(records)
    end

    return time_heap
  end

  def self.benchmark_merge(records) 
    time_merge = Benchmark.realtime do
      sorted_records =  merge_sort(records)
    end
    return time_merge
  end

    def self.merge_sort(records)
      return records if records.length <= 1
      mid = records.length / 2
      left_sorted = merge_sort(records[0...mid])
      right_sorted = merge_sort(records[mid..])

      merge(left_sorted, right_sorted)
    end

    def self.merge(left, right)
      sorted = []
      until left.empty? || right.empty?
        if left.first.recorded_at <= right.first.recorded_at
          sorted << left.first
          left = left.drop(1)
        else
          sorted << right.first
          right = right.drop(1)
        end
      end
      sorted + left + right
    end

    def self.heap_sort(records, attr_sym = :recorded_at)
      records_arr = records.to_a
      return records_arr if records_arr.empty?

      # Build max heap
      n = records_arr.length - 1
      i = n / 2
      while i >= 0 do
        heapify(records_arr, i, n, attr_sym)
        i -= 1
      end

      # One by one extract elements
      while n > 0 do
        records_arr[0], records_arr[n] = records_arr[n], records_arr[0] 
        n -= 1
        heapify(records_arr, 0, n, attr_sym) 
      end
      records_arr
    end

    private

    # Helper method to maintain the heap property
    def self.heapify(records, parent, limit, attr_sym)
      root = records[parent]
      while (child_node = 2 * parent + 1) <= limit do
        # Select the larger child
        if child_node < limit && records[child_node].send(attr_sym) < records[child_node + 1].send(attr_sym)
          child_node += 1
        end
        # If root is already greater than the greatest child, break
        break if root.send(attr_sym) >= records[child_node].send(attr_sym)

        records[parent] = records[child_node]
        parent = child_node
      end
      records[parent] = root
    end


  # Filtering funtion, provided sorted records, filters using custom algorithm to determine the most relevant records
  def self.filter_records(records, target_datetime)
    # first find all records within ~one month (ignoring the year)
    filtered_records = filter_by_date(records, target_datetime, 15)
  
    # find all records within 2 hours of time and 1 month of date
    filtered_records = filter_by_time(filtered_records, target_datetime, 2.hours)

    # if no records are within 1 month, ignore date and just filter by time
    if filtered_records.empty?
      # if no records are within 2 hours, increment by 1 hours until increment is 6 hours
      filtered_records = filter_by_time(records, target_datetime, 2.hours, true, 6.hours)
      
      # if no records found within 6 hours, filter by date and increment by 10 days until records found
      if filtered_records.empty?
        increment = 20
        while increment <= 183 && filtered_records.empty?
          filtered_records = filter_by_date(records, target_datetime, increment)
          # increase search range by 10 days (5 on either side) each loop
          increment += 5
        end

        if filtered_records.empty?
          # if no records found, just return all records (guarenteed to have some records)
          # should never happen but good fallback
          filtered_records = records
        else
        # If records are found with the broader date range, attempt a final time filter
          filtered_records = filter_by_time(filtered_records, target_datetime, 2.hours, true, 24.hours)
        end
      end
    end
    filtered_records
  end

  # Filter records to find those within the same month and day, ignoring the year
  def self.filter_by_date(records, target_datetime, day_range = 15)
    # Select records where the month and day fall within the specified range around the target_date
    filtered_records = records.select do |record|
      # Extract the month and day from record's datetime and the target date
      record_month_day = [record.recorded_at.month, record.recorded_at.day]
      target_month_day = [target_datetime.month, target_datetime.day]

      # Calculate the day of the year for comparison, assuming non-leap year for simplicity
      record_day_of_year = month_day_to_day_of_year(record_month_day, false)
      target_day_of_year = month_day_to_day_of_year(target_month_day, false)

      # Check if the record's date falls within the day range around the target date
      (target_day_of_year - day_range..target_day_of_year + day_range).cover?(record_day_of_year)
    end
    filtered_records
  end

  # Helper method to convert month and day to a day of the year
  def self.month_day_to_day_of_year(month_day, leap_year)
    month, day = month_day
    days_before_month = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334]
    days_before_month[month - 1] + day + (leap_year && month > 2 ? 1 : 0)
  end

  def self.filter_by_time(records, target_datetime, range, increment = false, limit = 6.hours)
    # Extract only the time part of the target_datetime
    # All other ways of doing this weren't working
    target_time_of_day = target_datetime.seconds_since_midnight
  
    # Initial filter based on the time range
    filtered_records = records.select do |record|
      record_time_of_day = record.recorded_at.seconds_since_midnight
      time_diff = (record_time_of_day - target_time_of_day).abs
      time_diff <= range
    end
    
    # Loop for incrementing search range if no records are found and increment is true
    if filtered_records.empty? && increment
      new_range = range
      while new_range < limit
        new_range += 1.hour  
        filtered_records = records.select do |record|
          record_time_of_day = record.recorded_at.seconds_since_midnight
          time_diff = (record_time_of_day - target_time_of_day).abs
          time_diff <= new_range
        end
  
        if filtered_records.any?
          # puts "Found #{filtered_records.count} records within #{new_range} seconds of target time."
          break
        end
      end
    end
  
    filtered_records
  end
end