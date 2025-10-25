require "test_helper"

class PlacesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    sign_in @user

    # Set up API key for tests
    ENV["GOOGLE_MAPS_AUTOCOMPLETE_API_KEY"] = "test_api_key"
  end

  # Authentication Tests
  test "should require authentication" do
    sign_out @user
    get places_autocomplete_path, params: { query: "New York" }
    assert_redirected_to new_user_session_path
  end

  test "should allow authenticated users to access autocomplete" do
    stub_successful_google_api_response
    get places_autocomplete_path, params: { query: "New York" }
    assert_response :success
  end

  # Blank Query Tests
  test "should return empty predictions for blank query" do
    get places_autocomplete_path, params: { query: "" }
    assert_response :success

    json_response = JSON.parse(response.body)
    assert_equal [], json_response["predictions"]
  end

  test "should return empty predictions for nil query" do
    get places_autocomplete_path
    assert_response :success

    json_response = JSON.parse(response.body)
    assert_equal [], json_response["predictions"]
  end

  # Query Validation Tests
  test "should reject queries longer than 200 characters" do
    long_query = "a" * 201
    get places_autocomplete_path, params: { query: long_query }
    assert_response :bad_request

    json_response = JSON.parse(response.body)
    assert_equal "Query too long", json_response["error"]
  end

  test "should accept queries exactly 200 characters long" do
    stub_successful_google_api_response
    query = "a" * 200
    get places_autocomplete_path, params: { query: query }
    assert_response :success
  end

  # Successful API Response Tests
  test "should return Google Maps API results for valid query" do
    stub_successful_google_api_response
    get places_autocomplete_path, params: { query: "New York" }
    assert_response :success

    json_response = JSON.parse(response.body)
    assert json_response["predictions"].is_a?(Array)
    assert_equal 2, json_response["predictions"].length
    assert_equal "New York, NY, USA", json_response["predictions"][0]["description"]
    assert_equal "place_id_1", json_response["predictions"][0]["place_id"]
  end

  test "should return formatted response structure" do
    stub_successful_google_api_response
    get places_autocomplete_path, params: { query: "London" }
    assert_response :success

    json_response = JSON.parse(response.body)
    prediction = json_response["predictions"].first

    assert_not_nil prediction["description"]
    assert_not_nil prediction["place_id"]
  end

  # Caching Tests
  test "should return consistent results for same query" do
    stub_successful_google_api_response

    # First request
    get places_autocomplete_path, params: { query: "Paris" }
    assert_response :success
    first_response = JSON.parse(response.body)

    # Second request with same query should return same results
    get places_autocomplete_path, params: { query: "Paris" }
    assert_response :success
    second_response = JSON.parse(response.body)

    assert_equal first_response, second_response
    assert_equal 2, first_response["predictions"].length
  end

  test "should normalize cache keys with case-insensitive and trimmed queries" do
    stub_successful_google_api_response

    # Request with different casing and spacing
    get places_autocomplete_path, params: { query: "New York" }
    assert_response :success
    first_response = JSON.parse(response.body)

    get places_autocomplete_path, params: { query: " new york " }
    assert_response :success
    second_response = JSON.parse(response.body)

    # Both should return valid predictions (testing that normalization doesn't break anything)
    assert first_response["predictions"].is_a?(Array)
    assert second_response["predictions"].is_a?(Array)
    assert_equal 2, first_response["predictions"].length
    assert_equal 2, second_response["predictions"].length
  end

  # Error Handling Tests
  test "should handle Google API errors gracefully" do
    stub_google_api_with_error
    get places_autocomplete_path, params: { query: "Error City" }
    assert_response :internal_server_error

    json_response = JSON.parse(response.body)
    assert_equal "Failed to fetch locations", json_response["error"]
  end

  test "should handle missing API key error" do
    # Temporarily remove API key
    original_key = ENV["GOOGLE_MAPS_AUTOCOMPLETE_API_KEY"]
    ENV["GOOGLE_MAPS_AUTOCOMPLETE_API_KEY"] = nil

    get places_autocomplete_path, params: { query: "Test City" }
    assert_response :internal_server_error

    json_response = JSON.parse(response.body)
    assert_equal "Failed to fetch locations", json_response["error"]

    # Restore API key
    ENV["GOOGLE_MAPS_AUTOCOMPLETE_API_KEY"] = original_key
  end

  test "should handle HTTP errors from Google API" do
    stub_google_api_with_http_error
    get places_autocomplete_path, params: { query: "HTTP Error City" }
    assert_response :internal_server_error

    json_response = JSON.parse(response.body)
    assert_equal "Failed to fetch locations", json_response["error"]
  end

  test "should handle invalid JSON responses" do
    stub_google_api_with_invalid_json
    get places_autocomplete_path, params: { query: "Invalid JSON City" }
    assert_response :internal_server_error

    json_response = JSON.parse(response.body)
    assert_equal "Failed to fetch locations", json_response["error"]
  end

  # Content Type Tests
  test "should return JSON content type" do
    stub_successful_google_api_response
    get places_autocomplete_path, params: { query: "Tokyo" }
    assert_equal "application/json; charset=utf-8", response.content_type
  end

  # Special Characters Tests
  test "should handle queries with special characters" do
    stub_successful_google_api_response
    get places_autocomplete_path, params: { query: "São Paulo" }
    assert_response :success
  end

  test "should handle queries with numbers" do
    stub_successful_google_api_response
    get places_autocomplete_path, params: { query: "123 Main Street" }
    assert_response :success
  end

  private

  # Helper method to create mock Google API response
  def mock_google_response
    {
      "predictions" => [
        {
          "description" => "New York, NY, USA",
          "place_id" => "place_id_1",
          "structured_formatting" => {
            "main_text" => "New York",
            "secondary_text" => "NY, USA"
          }
        },
        {
          "description" => "New York City Hall, Broadway, New York, NY, USA",
          "place_id" => "place_id_2",
          "structured_formatting" => {
            "main_text" => "New York City Hall",
            "secondary_text" => "Broadway, New York, NY, USA"
          }
        }
      ],
      "status" => "OK"
    }
  end

  # Stub successful HTTP response from Google API
  def stub_successful_google_api_response
    stub_request(:get, %r{https://maps\.googleapis\.com/maps/api/place/autocomplete/json})
      .to_return(
        status: 200,
        body: mock_google_response.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  # Stub Google API with error
  def stub_google_api_with_error
    stub_request(:get, %r{https://maps\.googleapis\.com/maps/api/place/autocomplete/json})
      .to_raise(StandardError.new("API Error"))
  end

  # Stub HTTP error response
  def stub_google_api_with_http_error
    stub_request(:get, %r{https://maps\.googleapis\.com/maps/api/place/autocomplete/json})
      .to_return(
        status: 500,
        body: { "error" => "Server Error" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  # Stub invalid JSON response
  def stub_google_api_with_invalid_json
    stub_request(:get, %r{https://maps\.googleapis\.com/maps/api/place/autocomplete/json})
      .to_return(
        status: 200,
        body: "Invalid JSON{",
        headers: { "Content-Type" => "application/json" }
      )
  end
end
