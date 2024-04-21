RGeo::ActiveRecord::SpatialFactoryStore.instance.tap do |config|
  # Use the RGeo::Geographic spherical factory for geographic columns
  config.default = RGeo::Geographic.spherical_factory(srid: 4326)
end