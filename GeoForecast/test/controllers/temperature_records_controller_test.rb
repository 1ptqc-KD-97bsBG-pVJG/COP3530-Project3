require "test_helper"

class TemperatureRecordsControllerTest < ActionDispatch::IntegrationTest
  test "should get search" do
    get temperature_records_search_url
    assert_response :success
  end
end
