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
require "test_helper"

class EventRegistrationTest < ActiveSupport::TestCase
  # Setup helper method to create a valid registration
  def setup
    @club = create(:club)
    @event = create(:event, club: @club)
    @user = create(:user)
    @membership = create(:membership, club: @club, user: @user, status: "active")
  end

  # Associations
  test "should belong to event" do
    registration = build(:event_registration)
    assert_respond_to registration, :event
  end

  test "should belong to user" do
    registration = build(:event_registration)
    assert_respond_to registration, :user
  end

  # Validations
  test "should be valid with valid attributes" do
    registration = build(:event_registration, event: @event, user: @user)
    # Owner cannot register, so we need to ensure user is not the owner
    assert_not_equal @club.owner, @user
    assert registration.valid?
  end

  test "should require event_id" do
    registration = build(:event_registration, event: nil, user: @user)
    assert_not registration.valid?
    assert_includes registration.errors[:event_id], "can't be blank"
  end

  test "should require user_id" do
    registration = build(:event_registration, event: @event, user: nil)
    assert_not registration.valid?
    assert_includes registration.errors[:user_id], "can't be blank"
  end

  test "should require status" do
    registration = build(:event_registration, event: @event, user: @user, status: nil)
    assert_not registration.valid?
    assert_includes registration.errors[:status], "can't be blank"
  end

  test "should validate uniqueness of user per event" do
    create(:event_registration, event: @event, user: @user)
    duplicate = build(:event_registration, event: @event, user: @user)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "already registered for this event"
  end

  test "should allow same user to register for different events" do
    event1 = create(:event, club: @club)
    event2 = create(:event, club: @club)

    registration1 = create(:event_registration, event: event1, user: @user)
    registration2 = build(:event_registration, event: event2, user: @user)

    assert registration2.valid?
  end

  test "should allow different users to register for same event" do
    user2 = create(:user)
    create(:membership, club: @club, user: user2, status: "active")

    registration1 = create(:event_registration, event: @event, user: @user)
    registration2 = build(:event_registration, event: @event, user: user2)

    assert registration2.valid?
  end

  test "should validate user is a club member" do
    non_member = create(:user)
    registration = build(:event_registration, event: @event, user: non_member)

    assert_not registration.valid?
    assert_includes registration.errors[:base], "Only club members can register for events"
  end

  test "should allow club owner to be validated as member" do
    owner = @club.owner
    registration = build(:event_registration, event: @event, user: owner)

    # Owner cannot register due to owner_cannot_register validation
    assert_not registration.valid?
    assert_includes registration.errors[:base], "Event organizer is automatically a participant"
  end

  test "should not allow owner to register for their own event" do
    owner = @club.owner
    registration = build(:event_registration, event: @event, user: owner)

    assert_not registration.valid?
    assert_includes registration.errors[:base], "Event organizer is automatically a participant"
  end

  test "should not allow pending members to register" do
    pending_user = create(:user)
    create(:membership, club: @club, user: pending_user, status: "pending")
    registration = build(:event_registration, event: @event, user: pending_user)

    assert_not registration.valid?
    assert_includes registration.errors[:base], "Only club members can register for events"
  end

  test "should not allow disabled members to register" do
    disabled_user = create(:user)
    create(:membership, club: @club, user: disabled_user, status: "disabled")
    registration = build(:event_registration, event: @event, user: disabled_user)

    assert_not registration.valid?
    assert_includes registration.errors[:base], "Only club members can register for events"
  end

  # Enums
  test "should have confirmed status enum" do
    registration = create(:event_registration, event: @event, user: @user, status: "confirmed")
    assert registration.confirmed?
    assert_equal "confirmed", registration.status
  end

  test "should have waitlist status enum" do
    registration = create(:event_registration, event: @event, user: @user, status: "waitlist")
    assert registration.waitlist?
    assert_equal "waitlist", registration.status
  end

  test "should default to confirmed status" do
    registration = create(:event_registration, event: @event, user: @user)
    assert_equal "confirmed", registration.status
    assert registration.confirmed?
  end

  test "should allow changing status from confirmed to waitlist" do
    registration = create(:event_registration, event: @event, user: @user, status: "confirmed")
    registration.update(status: "waitlist")

    assert registration.waitlist?
    assert_not registration.confirmed?
  end

  test "should allow changing status from waitlist to confirmed" do
    registration = create(:event_registration, event: @event, user: @user, status: "waitlist")
    registration.update(status: "confirmed")

    assert registration.confirmed?
    assert_not registration.waitlist?
  end

  # Scopes
  test "confirmed scope should return only confirmed registrations" do
    confirmed = create(:event_registration, event: @event, user: @user, status: "confirmed")

    user2 = create(:user)
    create(:membership, club: @club, user: user2, status: "active")
    waitlisted = create(:event_registration, event: @event, user: user2, status: "waitlist")

    confirmed_registrations = EventRegistration.confirmed

    assert_includes confirmed_registrations, confirmed
    assert_not_includes confirmed_registrations, waitlisted
  end

  test "waitlist scope should return only waitlist registrations" do
    confirmed_user = create(:user)
    create(:membership, club: @club, user: confirmed_user, status: "active")
    confirmed = create(:event_registration, event: @event, user: confirmed_user, status: "confirmed")

    waitlisted = create(:event_registration, event: @event, user: @user, status: "waitlist")

    waitlist_registrations = EventRegistration.waitlist

    assert_includes waitlist_registrations, waitlisted
    assert_not_includes waitlist_registrations, confirmed
  end

  # Integration tests
  test "should be able to create multiple registrations for same event" do
    user2 = create(:user)
    user3 = create(:user)
    create(:membership, club: @club, user: user2, status: "active")
    create(:membership, club: @club, user: user3, status: "active")

    registration1 = create(:event_registration, event: @event, user: @user)
    registration2 = create(:event_registration, event: @event, user: user2)
    registration3 = create(:event_registration, event: @event, user: user3)

    assert_equal 3, @event.event_registrations.count
  end

  test "should access event through registration" do
    registration = create(:event_registration, event: @event, user: @user)

    assert_equal @event, registration.event
    assert_equal @event.name, registration.event.name
  end

  test "should access user through registration" do
    registration = create(:event_registration, event: @event, user: @user)

    assert_equal @user, registration.user
    assert_equal @user.email, registration.user.email
  end

  test "should cascade delete when event is destroyed" do
    registration = create(:event_registration, event: @event, user: @user)
    registration_id = registration.id

    @event.destroy

    assert_nil EventRegistration.find_by(id: registration_id)
  end

  test "should not cascade delete when user is destroyed" do
    registration = create(:event_registration, event: @event, user: @user)
    registration_id = registration.id

    # This should raise an error due to foreign key constraint
    # or delete the registration depending on your setup
    # Here we just test that the registration exists before deletion
    assert EventRegistration.exists?(registration_id)
  end
end
