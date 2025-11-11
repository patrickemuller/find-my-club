require 'rails_helper'

RSpec.describe "Users::Profiles", type: :request do
  let(:user) { create(:user, :with_all_social_links) }

  describe "GET /users/:id" do
    it "displays the user profile page" do
      get user_path(user)

      expect(response).to have_http_status(:success)
      expect(response.body).to include(user.first_name)
      expect(response.body).to include(user.last_name)
    end

    it "displays social media links when present" do
      get user_path(user)

      # Check that usernames are displayed (extracted from URLs)
      expect(response.body).to include(user.strava_username) if user.strava_url.present?
      expect(response.body).to include(user.trailforks_username) if user.trailforks_url.present?
      expect(response.body).to include(user.outside_username) if user.outside_url.present?
      expect(response.body).to include(user.athlinks_username) if user.athlinks_url.present?
    end

    it "displays user clubs" do
      club = create(:club, public: true)
      create(:membership, user: user, club: club, status: :active)

      get user_path(user)

      expect(response.body).to include(club.name)
    end

    it "displays recent events" do
      club = create(:club, public: true)
      create(:membership, user: user, club: club, status: :active)

      # Create past event without validation
      past_event = Event.new(
        club: club,
        name: "Past Event",
        description: "A past event",
        starts_at: 1.week.ago,
        ends_at: 1.week.ago + 2.hours,
        max_participants: 10,
        has_waitlist: false,
        location: "https://maps.google.com/?q=test",
        location_name: "Test Location"
      )
      past_event.save(validate: false)

      create(:event_registration, user: user, event: past_event, status: :confirmed)

      get user_path(user)

      expect(response.body).to include(past_event.name)
    end
  end
end
