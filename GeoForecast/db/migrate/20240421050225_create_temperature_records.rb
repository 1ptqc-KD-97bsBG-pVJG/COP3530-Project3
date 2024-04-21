class CreateTemperatureRecords < ActiveRecord::Migration[7.0]
  def change
    create_table :temperature_records do |t|
      t.st_point :location, geographic: true
      t.datetime :recorded_at
      t.float :outside_temp
      t.float :speed
      t.float :elevation

      t.timestamps
    end
    add_index :temperature_records, :location, using: :gist
  end
end
