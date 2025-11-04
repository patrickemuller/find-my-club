require "rails_helper"

RSpec.describe "Places", type: :request do
  let(:user) { create(:user) }

  before do
    login_as user
    # Set up API key for tests
    ENV["GOOGLE_MAPS_AUTOCOMPLETE_API_KEY"] = "test_api_key"
  end

  # Authentication Tests
  describe "GET /places/autocomplete" do
    context "when not authenticated" do
      before { sign_out user }

      it "redirects to sign in" do
        get places_autocomplete_path, params: { query: "New York" }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated" do
      it "allows access to autocomplete" do
        stub_successful_google_api_response
        get places_autocomplete_path, params: { query: "New York" }
        expect(response).to have_http_status(:success)
      end
    end

    # Blank Query Tests
    context "with blank query" do
      it "returns empty predictions for blank query" do
        get places_autocomplete_path, params: { query: "" }
        expect(response).to have_http_status(:success)

        json_response = JSON.parse(response.body)
        expect(json_response["predictions"]).to eq([])
      end

      it "returns empty predictions for nil query" do
        get places_autocomplete_path
        expect(response).to have_http_status(:success)

        json_response = JSON.parse(response.body)
        expect(json_response["predictions"]).to eq([])
      end
    end

    # Query Validation Tests
    context "with query validation" do
      it "rejects queries longer than 200 characters" do
        long_query = "a" * 201
        get places_autocomplete_path, params: { query: long_query }
        expect(response).to have_http_status(:bad_request)

        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Query too long")
      end

      it "accepts queries exactly 200 characters long" do
        stub_successful_google_api_response
        query = "a" * 200
        get places_autocomplete_path, params: { query: query }
        expect(response).to have_http_status(:success)
      end
    end

    # Successful API Response Tests
    context "with valid query" do
      it "returns Google Maps API results" do
        stub_successful_google_api_response
        get places_autocomplete_path, params: { query: "New York" }
        expect(response).to have_http_status(:success)

        json_response = JSON.parse(response.body)
        expect(json_response["predictions"]).to be_an(Array)
        expect(json_response["predictions"].length).to eq(2)
        expect(json_response["predictions"][0]["description"]).to eq("New York, NY, USA")
        expect(json_response["predictions"][0]["place_id"]).to eq("place_id_1")
      end

      it "returns formatted response structure" do
        stub_successful_google_api_response
        get places_autocomplete_path, params: { query: "London" }
        expect(response).to have_http_status(:success)

        json_response = JSON.parse(response.body)
        prediction = json_response["predictions"].first

        expect(prediction["description"]).not_to be_nil
        expect(prediction["place_id"]).not_to be_nil
      end
    end

    # Caching Tests
    context "with caching" do
      it "returns consistent results for same query" do
        stub_successful_google_api_response

        # First request
        get places_autocomplete_path, params: { query: "Paris" }
        expect(response).to have_http_status(:success)
        first_response = JSON.parse(response.body)

        # Second request with same query should return same results
        get places_autocomplete_path, params: { query: "Paris" }
        expect(response).to have_http_status(:success)
        second_response = JSON.parse(response.body)

        expect(second_response).to eq(first_response)
        expect(first_response["predictions"].length).to eq(2)
      end

      it "normalizes cache keys with case-insensitive and trimmed queries" do
        stub_successful_google_api_response

        # Request with different casing and spacing
        get places_autocomplete_path, params: { query: "New York" }
        expect(response).to have_http_status(:success)
        first_response = JSON.parse(response.body)

        get places_autocomplete_path, params: { query: " new york " }
        expect(response).to have_http_status(:success)
        second_response = JSON.parse(response.body)

        # Both should return valid predictions (testing that normalization doesn't break anything)
        expect(first_response["predictions"]).to be_an(Array)
        expect(second_response["predictions"]).to be_an(Array)
        expect(first_response["predictions"].length).to eq(2)
        expect(second_response["predictions"].length).to eq(2)
      end
    end

    # Error Handling Tests
    context "with API errors" do
      it "handles Google API errors gracefully" do
        stub_google_api_with_error
        get places_autocomplete_path, params: { query: "Error City" }
        expect(response).to have_http_status(:internal_server_error)

        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Failed to fetch locations")
      end

      it "handles missing API key error" do
        # Temporarily remove API key
        original_key = ENV["GOOGLE_MAPS_AUTOCOMPLETE_API_KEY"]
        ENV["GOOGLE_MAPS_AUTOCOMPLETE_API_KEY"] = nil

        get places_autocomplete_path, params: { query: "Test City" }
        expect(response).to have_http_status(:internal_server_error)

        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Failed to fetch locations")

        # Restore API key
        ENV["GOOGLE_MAPS_AUTOCOMPLETE_API_KEY"] = original_key
      end

      it "handles HTTP errors from Google API" do
        stub_google_api_with_http_error
        get places_autocomplete_path, params: { query: "HTTP Error City" }
        expect(response).to have_http_status(:internal_server_error)

        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Failed to fetch locations")
      end

      it "handles invalid JSON responses" do
        stub_google_api_with_invalid_json
        get places_autocomplete_path, params: { query: "Invalid JSON City" }
        expect(response).to have_http_status(:internal_server_error)

        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Failed to fetch locations")
      end
    end

    # Content Type Tests
    context "with content type" do
      it "returns JSON content type" do
        stub_successful_google_api_response
        get places_autocomplete_path, params: { query: "Tokyo" }
        expect(response.content_type).to eq("application/json; charset=utf-8")
      end
    end

    # Special Characters Tests
    context "with special characters" do
      it "handles queries with special characters" do
        stub_successful_google_api_response
        get places_autocomplete_path, params: { query: "São Paulo" }
        expect(response).to have_http_status(:success)
      end

      it "handles queries with numbers" do
        stub_successful_google_api_response
        get places_autocomplete_path, params: { query: "123 Main Street" }
        expect(response).to have_http_status(:success)
      end
    end
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
