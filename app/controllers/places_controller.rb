class PlacesController < ApplicationController
  # Require authentication to prevent abuse
  before_action :authenticate_user!
  # Skip CSRF verification for autocomplete API endpoint
  skip_before_action :verify_authenticity_token, only: :autocomplete

  def autocomplete
    query = params[:query]

    if query.blank?
      render json: { predictions: [] }, status: :ok
      return
    end

    # Sanitize query to prevent abuse
    if query.length > 200
      render json: { error: "Query too long" }, status: :bad_request
      return
    end

    # Call Google Places Autocomplete API with caching
    begin
      results = fetch_with_cache(query)
      render json: results, status: :ok
    rescue StandardError => e
      Rails.logger.error("Google Places API error: #{e.message}")
      render json: { error: "Failed to fetch locations" }, status: :internal_server_error
    end
  end

  private

  def fetch_with_cache(query)
    # Use Rails cache with a 1-hour expiration to reduce API calls
    Rails.cache.fetch("google_places_autocomplete:#{query.downcase.strip}", expires_in: 1.hour) do
      fetch_google_places_autocomplete(query)
    end
  end

  def fetch_google_places_autocomplete(query)
    require "net/http"
    require "uri"
    require "json"

    api_key = ENV["GOOGLE_MAPS_AUTOCOMPLETE_API_KEY"]

    if api_key.blank?
      raise "GOOGLE_MAPS_AUTOCOMPLETE_API_KEY environment variable is not set"
    end

    # Build the Google Places Autocomplete API URL
    base_url = "https://maps.googleapis.com/maps/api/place/autocomplete/json"
    params = {
      input: query,
      key: api_key,
      types: "establishment|geocode" # Same as the original implementation
    }

    uri = URI.parse(base_url)
    uri.query = URI.encode_www_form(params)

    # Make the HTTP request
    response = Net::HTTP.get_response(uri)

    unless response.is_a?(Net::HTTPSuccess)
      raise "Google API returned status #{response.code}: #{response.body}"
    end

    # Parse and return the JSON response
    JSON.parse(response.body)
  end
end
