class TemperatureRecord < ApplicationRecord
  # TODO: switch to this implementation
  # def self.find_and_process_records(latitude, longitude, initial_radius = 2000, increment_step = 1000, max_radius = 2000000, datetime, sort_algo)
  #   records = find_nearby_records(latitude, longitude, initial_radius, increment_step, max_radius)
  #   sorted_records = process_sorting(records, datetime, sort_algo)
  #   filtered_records = filter_records(sorted_records, datetime)

  #   filtered_records
  # end



  # Method to find records within a specified radius around a point
  # If no records are found in the initial search, it will expand the search radius incrementally
  # If records are found after expanding the radius, it will further expand the radius by 2000 meters to capture nearby records
  
  # max_radius set to furthest point on continental US from data
  def self.find_nearby_records(latitude, longitude, initial_radius = 2000, increment_step = 1000, max_radius = 2000000, datetime = DateTime.now, sort_algo = 1)
      location_point = RGeo::Geographic.spherical_factory(srid: 4326).point(longitude, latitude)
      radius = initial_radius
      records = where("ST_DWithin(location, ST_SetSRID(ST_MakePoint(?, ?), 4326), ?)", longitude, latitude, radius)
                .order(Arel.sql("ST_Distance(location, ST_SetSRID(ST_MakePoint(#{longitude}, #{latitude}), 4326))"))
      # Flag to check if radius was ever incremented
      radius_incremented = false

      while records.none? && radius <= max_radius
        puts "Radius: " + radius.to_s
        radius += increment_step
        radius_incremented = true
        records = where("ST_DWithin(location, ST_SetSRID(ST_MakePoint(?, ?), 4326), ?)", longitude, latitude, radius)
                .order(Arel.sql("ST_Distance(location, ST_SetSRID(ST_MakePoint(#{longitude}, #{latitude}), 4326))"))
        puts "Found: " + records.count.to_s + " records"

      end

      # If records are found after incrementing, and radius can be further expanded by 2000 meters, do so
      if records.any? && radius_incremented && (radius + 2000) <= max_radius
        radius += 2000
        records = where("ST_DWithin(location, ST_SetSRID(ST_MakePoint(?, ?), 4326), ?)", longitude, latitude, radius)
                .order(Arel.sql("ST_Distance(location, ST_SetSRID(ST_MakePoint(#{longitude}, #{latitude}), 4326))"))
        puts "Found additional: " + records.count.to_s + " records"

      end


    # TODO: call sorting function(s) here, provide records as input

      # use user-pvoided flag to determine which sorting algorithm to use
      # if sort_algo = 0
      # sorted_records = merge_sort(records)
      # elif sort_algo = 1
        # sorted_records = sort_heap(records, datetime)
      # else
        # sorted_records = run both

    # filtered_records = self.filter_records(sorted_records, datetime)

    # records.to_a
    heap_sort(records.to_a)
    # filtered_records
   end
#
#   # NOTE: records may already be sorted by date, verify this and randomize prior to sorting if necessary
#
#   # TODO: implement sorting algorithm 1

    def self.merge_sort(records)
        return records if records.length <= 1

        mid = records.length / 2
        left_sorted = merge_sort(records[0...mid])
        right_sorted = merge_sort(records[mid..])

        merge(left_sorted, right_sorted)
      end

      private

      def self.merge(left, right)
        sorted = []
        while left.any? && right.any?
          if left.first.recorded_at <= right.first.recorded_at
            sorted << left.shift
          else
            sorted << right.shift
          end
        end
        sorted + left + right
      end


    def self.heap_sort(records, attr_sym = :recorded_at)
        n = records.length
        # Build max heap
        (n / 2 - 1).downto(0) do |i|
          heapify(records, n, i, attr_sym)
        end

        # One by one extract elements
        (n - 1).downto(1) do |i|
          records[i], records[0] = records[0], records[i]  # swap
          heapify(records, i, 0, attr_sym)  # call max heapify on the reduced heap
        end
        records
      end

      private

      # Helper method to maintain the heap property
      def self.heapify(records, n, i, attr_sym)
        largest = i  # Initialize largest as root
        left = 2 * i + 1  # left = 2*i + 1
        right = 2 * i + 2  # right = 2*i + 2

        # If left child is larger than root
        largest = left if left < n && records[left].send(attr_sym) > records[largest].send(attr_sym)

        # If right child is larger than largest so far
        largest = right if right < n && records[right].send(attr_sym) > records[largest].send(attr_sym)

        # If largest is not root
        if largest != i
          records[i], records[largest] = records[largest], records[i]  # swap
          heapify(records, n, largest, attr_sym)  # Recursively heapify the affected sub-tree
        end
      end
#
#   # TODO: implement sorting algorithm performance tracking
#
#   #TODO: filter sorted records:
#   def self.filter_records(records, datetime) {
#     # first find all records within one month
      filtered_records = filter_by_date(records, datetime, 1.month)
#
    # find all records within 2 hours of time and 1 month of date
      filtered_records = filter_by_time(filtered_records, datetime, 2.hours)

     # if no records are within 1 month, ignore date and just filter by time
      if filtered_records.empty?
        # if no records are within 2 hours, increment by 1 hours until increment is 6 hours
        filtered_records = filter_by_time(records, datetime, 2.hours, true, 6.hours)
        
        # if no records found within 6 hours, filter by date and increment by 1 month until records found
        if filtered_records.empty?
          filtered_records = filter_by_date(records, datetime, 1.month, true)

          if filtered_records.empty?
            # if no records found, just return records (guarenteed to have some records)
            return records
          end
        end
      end
          # if no records are found, return records
#
#   }
#
  # Filter records to find those within the same month and day, ignoring the year
  def self.filter_by_date(records, target_datetime, day_range = 15, increment = false) {
    # Select records where the month and day fall within the specified range around the target_date
    filtered_records = records.select do |record|
      # Extract the month and day from record's datetime and the target date
      record_month_day = [record.recorded_at.month, record.recorded_at.day]
      target_month_day = [target_datetime.month, target_datetime.day]

      
    end

#     # loop for incrementing search range

#
#
#     # if range = 12.months, return records
    filtered_records
  }

  def self.filter_by_time(records, target_datetime, range, increment = false, limit = 6.hours) {
    # ignore date and find all records within the range of the time
    filtered_records = records.select { |record| record.datetime.to_time >= date.to_time && record.datetime.to_time <= (datetime + range).to_time }
    
    # loop for incrementing search range
    if filtered_records.empty? && increment
      # conintually increase range by 1 hour until limit is reached
      while filtered_records.empty? && range <= limit
        range += 1.hour
        filtered_records = records.select { |record| record.datetime.to_time >= date.to_time && record.datetime.to_time <= (datetime + range).to_time }
      end
    end
    filtered_records
  }
end