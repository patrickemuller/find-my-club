# == Schema Information
#
# Table name: events
#
#  id               :bigint           not null, primary key
#  ends_at          :datetime         not null
#  has_waitlist     :boolean          default(FALSE), not null
#  location         :string           not null
#  location_name    :string           not null
#  max_participants :integer          default(10), not null
#  name             :string           not null
#  slug             :string
#  starts_at        :datetime         not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  club_id          :bigint           not null
#
# Indexes
#
#  index_events_on_club_id  (club_id)
#  index_events_on_slug     (slug) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (club_id => clubs.id)
#
require "rails_helper"

RSpec.describe Event, type: :model do
  let(:event) { build(:event) }

  describe "associations" do
    it "belongs to club" do
      expect(event).to respond_to(:club)
    end

    it "has many event_registrations" do
      event.save!
      expect(event).to respond_to(:event_registrations)
    end

    it "has many participants through event_registrations" do
      event.save!
      expect(event).to respond_to(:participants)
    end

    it "destroys dependent event_registrations when destroyed" do
      event.save!
      club = event.club
      user = create(:user)
      create(:membership, club: club, user: user, status: "active")
      create(:event_registration, event: event, user: user)

      expect { event.destroy }.to change(EventRegistration, :count).by(-1)
    end
  end

  describe "validations" do
    it "is valid with valid attributes" do
      expect(event).to be_valid
    end

    it "requires name" do
      event.name = nil
      expect(event).not_to be_valid
      expect(event.errors[:name]).to include("can't be blank")
    end

    it "requires location" do
      event.location = nil
      expect(event).not_to be_valid
      expect(event.errors[:location]).to include("can't be blank")
    end

    it "requires location_name" do
      event.location_name = nil
      expect(event).not_to be_valid
      expect(event.errors[:location_name]).to include("can't be blank")
    end

    it "requires starts_at" do
      event.starts_at = nil
      expect(event).not_to be_valid
      expect(event.errors[:starts_at]).to include("can't be blank")
    end

    it "requires ends_at" do
      event.ends_at = nil
      expect(event).not_to be_valid
      expect(event.errors[:ends_at]).to include("can't be blank")
    end

    it "requires description" do
      event.description = nil
      expect(event).not_to be_valid
      expect(event.errors[:description]).to include("can't be blank")
    end

    it "requires max_participants" do
      event.max_participants = nil
      expect(event).not_to be_valid
      expect(event.errors[:max_participants]).to include("can't be blank")
    end

    it "requires max_participants to be at least 2" do
      event.max_participants = 1
      expect(event).not_to be_valid
      expect(event.errors[:max_participants]).to include("must be greater than or equal to 2")
    end

    it "accepts max_participants of 2 or more" do
      event.max_participants = 2
      expect(event).to be_valid

      event.max_participants = 100
      expect(event).to be_valid
    end

    it "validates ends_at is after starts_at" do
      event.starts_at = 2.days.from_now
      event.ends_at = 1.day.from_now
      expect(event).not_to be_valid
      expect(event.errors[:ends_at]).to include("must be after start date")
    end

    it "does not allow ends_at to equal starts_at" do
      time = 1.day.from_now
      event.starts_at = time
      event.ends_at = time
      expect(event).not_to be_valid
      expect(event.errors[:ends_at]).to include("must be after start date")
    end

    it "validates starts_at is in the future on create" do
      event.starts_at = 1.hour.ago
      event.ends_at = Time.current
      expect(event).not_to be_valid
      expect(event.errors[:starts_at]).to include("must be in the future")
    end

    it "allows past starts_at on update" do
      event.save!
      event.name = "Updated Event"
      event.starts_at = 1.hour.ago
      event.ends_at = Time.current
      expect(event).to be_valid
    end
  end

  describe "scopes" do
    describe ".upcoming" do
      it "returns only future events" do
        past_event = build(:event, :past)
        past_event.save(validate: false)
        upcoming_event = create(:event)

        upcoming = Event.upcoming

        expect(upcoming).to include(upcoming_event)
        expect(upcoming).not_to include(past_event)
      end

      it "orders by starts_at ascending" do
        event1 = create(:event, starts_at: 3.days.from_now, ends_at: 3.days.from_now + 2.hours)
        event2 = create(:event, starts_at: 1.day.from_now, ends_at: 1.day.from_now + 2.hours)
        event3 = create(:event, starts_at: 2.days.from_now, ends_at: 2.days.from_now + 2.hours)

        upcoming = Event.upcoming.to_a

        expect(upcoming).to eq([ event2, event3, event1 ])
      end
    end

    describe ".past" do
      it "returns only past events" do
        past_event = build(:event, :past)
        past_event.save(validate: false)
        upcoming_event = create(:event)

        past = Event.past

        expect(past).to include(past_event)
        expect(past).not_to include(upcoming_event)
      end

      it "orders by starts_at descending" do
        event1 = build(:event, starts_at: 3.days.ago, ends_at: 3.days.ago + 2.hours)
        event1.save(validate: false)
        event2 = build(:event, starts_at: 1.day.ago, ends_at: 1.day.ago + 2.hours)
        event2.save(validate: false)
        event3 = build(:event, starts_at: 2.days.ago, ends_at: 2.days.ago + 2.hours)
        event3.save(validate: false)

        past = Event.past.to_a

        expect(past).to eq([ event2, event3, event1 ])
      end
    end
  end

  describe "FriendlyId" do
    it "generates slug from name" do
      event.name = "Weekly Training Session"
      event.save!
      expect(event.slug).not_to be_nil
      expect(event.slug).to eq("weekly-training-session")
    end

    it "regenerates slug when name changes" do
      event.save!
      original_slug = event.slug

      event.update(name: "New Name")
      expect(event.slug).not_to eq(original_slug)
      expect(event.slug).to eq("new-name")
    end
  end

  describe "instance methods" do
    describe "#in_progress?" do
      it "returns true for future events" do
        event.starts_at = 1.day.from_now
        event.ends_at = 1.day.from_now + 2.hours
        event.save!
        expect(event).to be_in_progress
      end

      it "returns false for past events" do
        past_event = build(:event, :past)
        past_event.save(validate: false)
        expect(past_event).not_to be_in_progress
      end
    end

    describe "#full?" do
      it "returns true when event is at capacity" do
        event.max_participants = 2
        event.save!
        club = event.club
        user1 = create(:user)
        user2 = create(:user)
        create(:membership, club: club, user: user1, status: "active")
        create(:membership, club: club, user: user2, status: "active")

        create(:event_registration, event: event, user: user1, status: "confirmed")
        create(:event_registration, event: event, user: user2, status: "confirmed")

        expect(event).to be_full
      end

      it "returns false when event has available spots" do
        event.max_participants = 10
        event.save!
        club = event.club
        user = create(:user)
        create(:membership, club: club, user: user, status: "active")
        create(:event_registration, event: event, user: user, status: "confirmed")

        expect(event).not_to be_full
      end

      it "only counts confirmed registrations" do
        event.max_participants = 2
        event.save!
        club = event.club
        user1 = create(:user)
        user2 = create(:user)
        user3 = create(:user)
        create(:membership, club: club, user: user1, status: "active")
        create(:membership, club: club, user: user2, status: "active")
        create(:membership, club: club, user: user3, status: "active")

        create(:event_registration, event: event, user: user1, status: "confirmed")
        create(:event_registration, event: event, user: user2, status: "waitlist")
        create(:event_registration, event: event, user: user3, status: "waitlist")

        expect(event).not_to be_full
      end
    end

    describe "#confirmed_participants_count" do
      it "returns count of confirmed registrations" do
        event.save!
        club = event.club
        user1 = create(:user)
        user2 = create(:user)
        user3 = create(:user)
        create(:membership, club: club, user: user1, status: "active")
        create(:membership, club: club, user: user2, status: "active")
        create(:membership, club: club, user: user3, status: "active")

        create(:event_registration, event: event, user: user1, status: "confirmed")
        create(:event_registration, event: event, user: user2, status: "confirmed")
        create(:event_registration, event: event, user: user3, status: "waitlist")

        expect(event.confirmed_participants_count).to eq(2)
      end
    end

    describe "#waitlist_participants_count" do
      it "returns count of waitlist registrations" do
        event.save!
        club = event.club
        user1 = create(:user)
        user2 = create(:user)
        user3 = create(:user)
        create(:membership, club: club, user: user1, status: "active")
        create(:membership, club: club, user: user2, status: "active")
        create(:membership, club: club, user: user3, status: "active")

        create(:event_registration, event: event, user: user1, status: "confirmed")
        create(:event_registration, event: event, user: user2, status: "waitlist")
        create(:event_registration, event: event, user: user3, status: "waitlist")

        expect(event.waitlist_participants_count).to eq(2)
      end
    end

    describe "#available_spots" do
      it "returns remaining capacity" do
        event.max_participants = 5
        event.save!
        club = event.club
        user1 = create(:user)
        user2 = create(:user)
        create(:membership, club: club, user: user1, status: "active")
        create(:membership, club: club, user: user2, status: "active")

        create(:event_registration, event: event, user: user1, status: "confirmed")
        create(:event_registration, event: event, user: user2, status: "confirmed")

        expect(event.available_spots).to eq(3)
      end

      it "returns 0 when event is full" do
        event.max_participants = 2
        event.save!
        club = event.club
        user1 = create(:user)
        user2 = create(:user)
        create(:membership, club: club, user: user1, status: "active")
        create(:membership, club: club, user: user2, status: "active")

        create(:event_registration, event: event, user: user1, status: "confirmed")
        create(:event_registration, event: event, user: user2, status: "confirmed")

        expect(event.available_spots).to eq(0)
      end
    end

    describe "#user_registered?" do
      it "returns true if user is registered" do
        event.save!
        club = event.club
        user = create(:user)
        create(:membership, club: club, user: user, status: "active")
        create(:event_registration, event: event, user: user)

        expect(event.user_registered?(user)).to be true
      end

      it "returns false if user is not registered" do
        event.save!
        user = create(:user)

        expect(event.user_registered?(user)).to be false
      end

      it "returns false for nil user" do
        event.save!
        expect(event.user_registered?(nil)).to be false
      end
    end

    describe "#user_registration_status" do
      it "returns registration status" do
        event.save!
        club = event.club
        user = create(:user)
        create(:membership, club: club, user: user, status: "active")
        create(:event_registration, event: event, user: user, status: "confirmed")

        expect(event.user_registration_status(user)).to eq("confirmed")
      end

      it "returns nil if user not registered" do
        event.save!
        user = create(:user)

        expect(event.user_registration_status(user)).to be_nil
      end

      it "returns nil for nil user" do
        event.save!
        expect(event.user_registration_status(nil)).to be_nil
      end
    end
  end
end
