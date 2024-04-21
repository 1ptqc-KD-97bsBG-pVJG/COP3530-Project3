class TemperatureRecord < ApplicationRecord
  # The initializer config/initializers/rgeo.rb sets the RGeo factory
  
  # VERY BASIC AND ITINIAL VALIDATION, FOR TESTING PURPOSES
  # RUN COMMAND TO TEST: TemperatureRecord.find_nearby_records(47.589719, -122.313504, 5000, 1000, 20000)
  # (replace long, lat coordinates with your own)

  # Method to find records within a specified radius around a point
  # If no records are found, it will expand the search radius
  def self.find_nearby_records(latitude, longitude, initial_radius, increment_step, max_radius)
    location_point = RGeo::Geographic.spherical_factory(srid: 4326).point(longitude, latitude)
    radius = initial_radius
    records = where("ST_DWithin(location, ST_SetSRID(ST_MakePoint(?, ?), 4326), ?)", longitude, latitude, radius)
    
    while records.none? && radius <= max_radius
      radius += increment_step
      records = where("ST_DWithin(location, ST_SetSRID(ST_MakePoint(?, ?), 4326), ?)", longitude, latitude, radius)
    end

    records
  end
end
