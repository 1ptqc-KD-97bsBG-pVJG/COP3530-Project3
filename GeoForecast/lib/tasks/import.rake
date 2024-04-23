# THIS IS A SCRIPT FOR IMPORTING THE CSV FILE INTO THE DATABASE
# (necessary because latitude and longitude must be converted to a point object)
# PLACE CSV TO BE IMPORTED RIGHT OUTSIDE OF THE 'GeoForecast' FOLDER
# Run command: bundle exec rake db:import_temperature_records
# to import the CSV file
# (it will take a while to run)

require 'csv'
namespace :db do
  desc "Import temperature records from a prepped CSV file"
  task import_temperature_records: :environment do
    
    csv_file_path = File.join(Rails.root, '..', 'cleaned_output.csv')
    factory = RGeo::Geographic.spherical_factory(srid: 4326)
    failed_rows = []
    success_count = 0
    skipped_rows = 0

    CSV.foreach(csv_file_path, headers: true, header_converters: :symbol) do |row|
      begin
        if row[:longitude].blank? || row[:latitude].blank? || row[:date].blank? || row[:outside_temp].blank?
          puts "Skipping row #{row[:data_id]} due to missing data"
          puts "Longitude is blank: #{row[:longitude].blank?}"
          puts "Latitude is blank: #{row[:latitude].blank?}"
          puts "Date is blank: #{row[:date].blank?}"
          puts "Outside Temp is blank: #{row[:outside_temp].blank?}"
          skipped_rows += 1
          next
        end

        TemperatureRecord.create!(
          location: factory.point(row[:longitude].to_f, row[:latitude].to_f),
          recorded_at: DateTime.parse(row[:date]),
          outside_temp: row[:outside_temp].to_f,
          speed: row[:speed].to_f,
          elevation: row[:elevation].to_f
        )
        success_count += 1
      rescue StandardError => e
        failed_rows << { data_id: row[:data_id], error: e.message }
        puts "Error importing row ##{row[:data_id]}: #{e.message}"
      end
    end

    puts "Import completed with #{success_count} records added, #{skipped_rows} rows skipped due to missing data, and #{failed_rows.size} rows failed."
  end
end