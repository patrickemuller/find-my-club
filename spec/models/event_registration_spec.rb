# == Schema Information
#
# Table name: event_registrations
#
#  id         :bigint           not null, primary key
#  status     :string           default("confirmed"), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  event_id   :bigint           not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_event_registrations_on_event_id              (event_id)
#  index_event_registrations_on_user_id               (user_id)
#  index_event_registrations_on_user_id_and_event_id  (user_id,event_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (event_id => events.id)
#  fk_rails_...  (user_id => users.id)
#
require "rails_helper"

RSpec.describe EventRegistration, type: :model do
  let(:club) { create(:club) }
  let(:event) { create(:event, club: club) }
  let(:user) { create(:user) }
  let(:event_registration) { build(:event_registration, event: event, user: user) }

  before do
    # Make user a member of the club so they can register for events
    create(:membership, user: user, club: club, status: "active")
  end

  describe "validations" do
    it "is valid with valid attributes" do
      expect(event_registration).to be_valid
    end

    it "requires event_id" do
      event_registration.event_id = nil
      expect(event_registration).not_to be_valid
      expect(event_registration.errors[:event_id]).to include("can't be blank")
    end

    it "requires user_id" do
      event_registration.user_id = nil
      expect(event_registration).not_to be_valid
      expect(event_registration.errors[:user_id]).to include("can't be blank")
    end

    it "requires status" do
      event_registration.status = nil
      expect(event_registration).not_to be_valid
      expect(event_registration.errors[:status]).to include("can't be blank")
    end

    it "requires unique user per event" do
      create(:event_registration, event: event, user: user)
      duplicate_registration = build(:event_registration, event: event, user: user)

      expect(duplicate_registration).not_to be_valid
      expect(duplicate_registration.errors[:user_id]).to include("already registered for this event")
    end

    it "allows same user to register for different events" do
      event2 = create(:event, club: club)
      create(:event_registration, event: event, user: user)
      registration2 = build(:event_registration, event: event2, user: user)

      expect(registration2).to be_valid
    end

    it "allows different users to register for same event" do
      user2 = create(:user)
      create(:membership, user: user2, club: club, status: "active")

      create(:event_registration, event: event, user: user)
      registration2 = build(:event_registration, event: event, user: user2)

      expect(registration2).to be_valid
    end
  end

  describe "associations" do
    it "belongs to event" do
      expect(event_registration).to respond_to(:event)
    end

    it "belongs to user" do
      expect(event_registration).to respond_to(:user)
    end
  end

  describe "enums" do
    it "has confirmed status" do
      event_registration.status = :confirmed
      expect(event_registration.confirmed?).to be true
    end

    it "has waitlist status" do
      event_registration.status = :waitlist
      expect(event_registration.waitlist?).to be true
    end
  end

  describe "scopes" do
    describe ".confirmed" do
      it "returns only confirmed registrations" do
        confirmed_reg = create(:event_registration, event: event, user: user, status: "confirmed")
        user2 = create(:user)
        create(:membership, user: user2, club: club, status: "active")
        waitlist_reg = create(:event_registration, event: event, user: user2, status: "waitlist")

        confirmed = EventRegistration.confirmed

        expect(confirmed).to include(confirmed_reg)
        expect(confirmed).not_to include(waitlist_reg)
      end
    end

    describe ".waitlist" do
      it "returns only waitlist registrations" do
        confirmed_reg = create(:event_registration, event: event, user: user, status: "confirmed")
        user2 = create(:user)
        create(:membership, user: user2, club: club, status: "active")
        waitlist_reg = create(:event_registration, event: event, user: user2, status: "waitlist")

        waitlist = EventRegistration.waitlist

        expect(waitlist).to include(waitlist_reg)
        expect(waitlist).not_to include(confirmed_reg)
      end
    end
  end

  describe "default values" do
    it "defaults status to confirmed" do
      new_registration = EventRegistration.new
      expect(new_registration.status).to eq("confirmed")
    end
  end

  describe "custom validations" do
    describe "#user_is_club_member" do
      it "is invalid when user is not a club member" do
        non_member = create(:user)
        registration = build(:event_registration, event: event, user: non_member)

        expect(registration).not_to be_valid
        expect(registration.errors[:base]).to include("Only club members can register for events")
      end

      it "is valid when user is an active member" do
        expect(event_registration).to be_valid
      end

      it "is valid when user is the club owner" do
        owner = club.owner
        # Owner validation will fail, so this tests the member check specifically
        registration = build(:event_registration, event: event, user: owner)

        registration.valid?
        # Should not have member error (will have owner error instead)
        expect(registration.errors[:base]).not_to include("Only club members can register for events")
      end

      it "is invalid when user is pending member" do
        pending_user = create(:user)
        create(:membership, :pending, user: pending_user, club: club)
        registration = build(:event_registration, event: event, user: pending_user)

        expect(registration).not_to be_valid
        expect(registration.errors[:base]).to include("Only club members can register for events")
      end

      it "is invalid when user is disabled member" do
        disabled_user = create(:user)
        create(:membership, :disabled, user: disabled_user, club: club)
        registration = build(:event_registration, event: event, user: disabled_user)

        expect(registration).not_to be_valid
        expect(registration.errors[:base]).to include("Only club members can register for events")
      end
    end

    describe "#owner_cannot_register" do
      it "is invalid when owner tries to register" do
        owner = club.owner
        registration = build(:event_registration, event: event, user: owner)

        expect(registration).not_to be_valid
        expect(registration.errors[:base]).to include("Event organizer is automatically a participant")
      end

      it "is valid when non-owner registers" do
        expect(event_registration).to be_valid
      end
    end
  end
end
