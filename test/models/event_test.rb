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
require "test_helper"

class EventTest < ActiveSupport::TestCase
  # Associations
  test "should belong to club" do
    event = build(:event)
    assert_respond_to event, :club
  end

  test "should have many event_registrations" do
    event = create(:event)
    assert_respond_to event, :event_registrations
  end

  test "should have many participants through event_registrations" do
    event = create(:event)
    assert_respond_to event, :participants
  end

  test "should destroy dependent event_registrations when destroyed" do
    event = create(:event)
    club = event.club
    user = create(:user)
    create(:membership, club: club, user: user, status: "active")
    create(:event_registration, event: event, user: user)

    assert_difference "EventRegistration.count", -1 do
      event.destroy
    end
  end

  # Validations
  test "should be valid with valid attributes" do
    event = build(:event)
    assert event.valid?
  end

  test "should require name" do
    event = build(:event, name: nil)
    assert_not event.valid?
    assert_includes event.errors[:name], "can't be blank"
  end

  test "should require location" do
    event = build(:event, location: nil)
    assert_not event.valid?
    assert_includes event.errors[:location], "can't be blank"
  end

  test "should require location_name" do
    event = build(:event, location_name: nil)
    assert_not event.valid?
    assert_includes event.errors[:location_name], "can't be blank"
  end

  test "should require starts_at" do
    event = build(:event, starts_at: nil)
    assert_not event.valid?
    assert_includes event.errors[:starts_at], "can't be blank"
  end

  test "should require ends_at" do
    event = build(:event, ends_at: nil)
    assert_not event.valid?
    assert_includes event.errors[:ends_at], "can't be blank"
  end

  test "should require description" do
    event = build(:event, description: nil)
    assert_not event.valid?
    assert_includes event.errors[:description], "can't be blank"
  end

  test "should require max_participants" do
    event = build(:event, max_participants: nil)
    assert_not event.valid?
    assert_includes event.errors[:max_participants], "can't be blank"
  end

  test "should require max_participants to be at least 2" do
    event = build(:event, max_participants: 1)
    assert_not event.valid?
    assert_includes event.errors[:max_participants], "must be greater than or equal to 2"
  end

  test "should accept max_participants of 2 or more" do
    event = build(:event, max_participants: 2)
    assert event.valid?

    event = build(:event, max_participants: 100)
    assert event.valid?
  end

  test "should validate ends_at is after starts_at" do
    event = build(:event, starts_at: 2.days.from_now, ends_at: 1.day.from_now)
    assert_not event.valid?
    assert_includes event.errors[:ends_at], "must be after start date"
  end

  test "should not allow ends_at to equal starts_at" do
    time = 1.day.from_now
    event = build(:event, starts_at: time, ends_at: time)
    assert_not event.valid?
    assert_includes event.errors[:ends_at], "must be after start date"
  end

  test "should validate starts_at is in the future on create" do
    event = build(:event, starts_at: 1.hour.ago, ends_at: Time.current)
    assert_not event.valid?
    assert_includes event.errors[:starts_at], "must be in the future"
  end

  test "should allow past starts_at on update" do
    event = create(:event, starts_at: 1.day.from_now, ends_at: 1.day.from_now + 2.hours)
    event.name = "Updated Event"
    event.starts_at = 1.hour.ago
    event.ends_at = Time.current
    assert event.valid?
  end

  # Scopes
  test "upcoming scope should return only future events" do
    past_event = build(:event, :past)
    past_event.save(validate: false)
    upcoming_event = create(:event)

    upcoming = Event.upcoming

    assert_includes upcoming, upcoming_event
    assert_not_includes upcoming, past_event
  end

  test "upcoming scope should order by starts_at ascending" do
    event1 = create(:event, starts_at: 3.days.from_now, ends_at: 3.days.from_now + 2.hours)
    event2 = create(:event, starts_at: 1.day.from_now, ends_at: 1.day.from_now + 2.hours)
    event3 = create(:event, starts_at: 2.days.from_now, ends_at: 2.days.from_now + 2.hours)

    upcoming = Event.upcoming.to_a

    assert_equal [ event2, event3, event1 ], upcoming
  end

  test "past scope should return only past events" do
    past_event = build(:event, :past)
    past_event.save(validate: false)
    upcoming_event = create(:event)

    past = Event.past

    assert_includes past, past_event
    assert_not_includes past, upcoming_event
  end

  test "past scope should order by starts_at descending" do
    event1 = build(:event, starts_at: 3.days.ago, ends_at: 3.days.ago + 2.hours)
    event1.save(validate: false)
    event2 = build(:event, starts_at: 1.day.ago, ends_at: 1.day.ago + 2.hours)
    event2.save(validate: false)
    event3 = build(:event, starts_at: 2.days.ago, ends_at: 2.days.ago + 2.hours)
    event3.save(validate: false)

    past = Event.past.to_a

    assert_equal [ event2, event3, event1 ], past
  end

  # FriendlyId
  test "should generate slug from name" do
    event = create(:event, name: "Weekly Training Session")
    assert_not_nil event.slug
    assert_equal "weekly-training-session", event.slug
  end

  test "should regenerate slug when name changes" do
    event = create(:event, name: "Original Name")
    original_slug = event.slug

    event.update(name: "New Name")
    assert_not_equal original_slug, event.slug
    assert_equal "new-name", event.slug
  end

  # Instance Methods
  test "in_progress? should return true for future events" do
    event = create(:event, starts_at: 1.day.from_now, ends_at: 1.day.from_now + 2.hours)
    assert event.in_progress?
  end

  test "in_progress? should return false for past events" do
    event = build(:event, :past)
    event.save(validate: false)
    assert_not event.in_progress?
  end

  test "full? should return true when event is at capacity" do
    event = create(:event, max_participants: 2)
    club = event.club
    user1 = create(:user)
    user2 = create(:user)
    create(:membership, club: club, user: user1, status: "active")
    create(:membership, club: club, user: user2, status: "active")

    create(:event_registration, event: event, user: user1, status: "confirmed")
    create(:event_registration, event: event, user: user2, status: "confirmed")

    assert event.full?
  end

  test "full? should return false when event has available spots" do
    event = create(:event, max_participants: 10)
    club = event.club
    user = create(:user)
    create(:membership, club: club, user: user, status: "active")
    create(:event_registration, event: event, user: user, status: "confirmed")

    assert_not event.full?
  end

  test "full? should only count confirmed registrations" do
    event = create(:event, max_participants: 2)
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

    assert_not event.full?
  end

  test "confirmed_participants_count should return count of confirmed registrations" do
    event = create(:event)
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

    assert_equal 2, event.confirmed_participants_count
  end

  test "waitlist_participants_count should return count of waitlist registrations" do
    event = create(:event)
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

    assert_equal 2, event.waitlist_participants_count
  end

  test "available_spots should return remaining capacity" do
    event = create(:event, max_participants: 5)
    club = event.club
    user1 = create(:user)
    user2 = create(:user)
    create(:membership, club: club, user: user1, status: "active")
    create(:membership, club: club, user: user2, status: "active")

    create(:event_registration, event: event, user: user1, status: "confirmed")
    create(:event_registration, event: event, user: user2, status: "confirmed")

    assert_equal 3, event.available_spots
  end

  test "available_spots should return 0 when event is full" do
    event = create(:event, max_participants: 2)
    club = event.club
    user1 = create(:user)
    user2 = create(:user)
    create(:membership, club: club, user: user1, status: "active")
    create(:membership, club: club, user: user2, status: "active")

    create(:event_registration, event: event, user: user1, status: "confirmed")
    create(:event_registration, event: event, user: user2, status: "confirmed")

    assert_equal 0, event.available_spots
  end

  test "user_registered? should return true if user is registered" do
    event = create(:event)
    club = event.club
    user = create(:user)
    create(:membership, club: club, user: user, status: "active")
    create(:event_registration, event: event, user: user)

    assert event.user_registered?(user)
  end

  test "user_registered? should return false if user is not registered" do
    event = create(:event)
    user = create(:user)

    assert_not event.user_registered?(user)
  end

  test "user_registered? should return false for nil user" do
    event = create(:event)
    assert_not event.user_registered?(nil)
  end

  test "user_registration_status should return registration status" do
    event = create(:event)
    club = event.club
    user = create(:user)
    create(:membership, club: club, user: user, status: "active")
    create(:event_registration, event: event, user: user, status: "confirmed")

    assert_equal "confirmed", event.user_registration_status(user)
  end

  test "user_registration_status should return nil if user not registered" do
    event = create(:event)
    user = create(:user)

    assert_nil event.user_registration_status(user)
  end

  test "user_registration_status should return nil for nil user" do
    event = create(:event)
    assert_nil event.user_registration_status(nil)
  end
end
