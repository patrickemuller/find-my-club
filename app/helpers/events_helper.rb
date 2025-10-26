module EventsHelper
  include ActionView::Helpers::SanitizeHelper

  def google_calendar_url(event)
    # Generate Google Calendar add event URL
    params = {
      action: "TEMPLATE",
      text: event.name,
      dates: "#{event.starts_at.strftime('%Y%m%dT%H%M%S')}/#{event.ends_at.strftime('%Y%m%dT%H%M%S')}",
      details: strip_tags(event.description.to_s),
      location: event.location_name || event.location
    }

    "https://calendar.google.com/calendar/render?#{params.to_query}"
  end

  def google_maps_embed_url(location_url)
    # Extract the query parameter from Google Maps URL and create an embeddable URL
    # This uses the standard Google Maps embed format that doesn't require an API key
    # Supports formats like:
    # - https://maps.google.com/?q=Location+Name
    # - https://www.google.com/maps/search/Location+Name
    # - https://maps.google.com/maps?q=40.7128,-74.0060

    begin
      uri = URI.parse(location_url)

      # Extract query parameter 'q' if present
      if uri.query
        query_params = CGI.parse(uri.query)
        query = query_params["q"]&.first

        if query
          # Build embed URL using standard Google Maps embed
          return "https://maps.google.com/maps?q=#{CGI.escape(query)}&output=embed"
        end
      end

      # If no query found, try to extract from path
      if uri.path && uri.path.include?("/search/")
        search_term = uri.path.split("/search/").last
        return "https://maps.google.com/maps?q=#{CGI.escape(search_term)}&output=embed"
      end

      # Fallback: use the entire URL as search query
      "https://maps.google.com/maps?q=#{CGI.escape(location_url)}&output=embed"
    rescue URI::InvalidURIError
      # If URL is invalid, treat it as a search term
      "https://maps.google.com/maps?q=#{CGI.escape(location_url)}&output=embed"
    end
  end
end
