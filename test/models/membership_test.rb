# == Schema Information
#
# Table name: memberships
#
#  id         :bigint           not null, primary key
#  role       :string           default("member"), not null
#  status     :string           default("active"), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  club_id    :bigint           not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_memberships_on_club_id              (club_id)
#  index_memberships_on_role                 (role)
#  index_memberships_on_status               (status)
#  index_memberships_on_user_id              (user_id)
#  index_memberships_on_user_id_and_club_id  (user_id,club_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (club_id => clubs.id)
#  fk_rails_...  (user_id => users.id)
#
require "test_helper"

class MembershipTest < ActiveSupport::TestCase
  def setup
    @user = create(:user)
    @club = create(:club)
    @membership = build(:membership, user: @user, club: @club)
  end

  # Validations
  test "should be valid with valid attributes" do
    assert @membership.valid?
  end

  test "should require user_id" do
    @membership.user = nil
    assert_not @membership.valid?
    assert_includes @membership.errors[:user_id], "can't be blank"
  end

  test "should require club_id" do
    @membership.club = nil
    assert_not @membership.valid?
    assert_includes @membership.errors[:club_id], "can't be blank"
  end

  test "should require status" do
    @membership.status = nil
    assert_not @membership.valid?
    assert_includes @membership.errors[:status], "can't be blank"
  end

  test "should require role" do
    @membership.role = nil
    assert_not @membership.valid?
    assert_includes @membership.errors[:role], "can't be blank"
  end

  test "should validate uniqueness of user_id scoped to club_id" do
    @membership.save!
    duplicate = build(:membership, user: @user, club: @club)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "is already a member of this club"
  end

  test "should allow same user to join different clubs" do
    @membership.save!
    other_club = create(:club)
    other_membership = build(:membership, user: @user, club: other_club)
    assert other_membership.valid?
  end

  test "should allow different users to join same club" do
    @membership.save!
    other_user = create(:user)
    other_membership = build(:membership, user: other_user, club: @club)
    assert other_membership.valid?
  end

  test "should validate status is in allowed values" do
    assert_raises(ArgumentError) do
      @membership.status = "invalid_status"
    end
  end

  test "should validate role is in allowed values" do
    assert_raises(ArgumentError) do
      @membership.role = "invalid_role"
    end
  end

  test "should not allow owner to be a member of their own club" do
    owner = @club.owner
    membership = build(:membership, user: owner, club: @club)
    assert_not membership.valid?
    assert_includes membership.errors[:base], "Club owner cannot be a member of it's own club"
  end

  # Enums
  test "should have active status enum" do
    @membership.status = "active"
    assert @membership.active?
  end

  test "should have pending status enum" do
    @membership.status = "pending"
    assert @membership.pending?
  end

  test "should have disabled status enum" do
    @membership.status = "disabled"
    assert @membership.disabled?
  end

  test "should have member role enum" do
    @membership.role = "member"
    assert @membership.member?
  end

  # Scopes
  test "should have active scope" do
    active_membership = create(:membership, status: "active")
    pending_membership = create(:membership, :pending)

    assert_includes Membership.active, active_membership
    assert_not_includes Membership.active, pending_membership
  end

  test "should have pending scope" do
    active_membership = create(:membership, status: "active")
    pending_membership = create(:membership, :pending)

    assert_includes Membership.pending, pending_membership
    assert_not_includes Membership.pending, active_membership
  end

  test "should have disabled scope" do
    active_membership = create(:membership, status: "active")
    disabled_membership = create(:membership, :disabled)

    assert_includes Membership.disabled, disabled_membership
    assert_not_includes Membership.disabled, active_membership
  end

  # Associations
  test "should belong to user" do
    assert_respond_to @membership, :user
  end

  test "should belong to club" do
    assert_respond_to @membership, :club
  end

  # Default values
  test "should have default status of active" do
    membership = Membership.new(user: @user, club: @club)
    assert_equal "active", membership.status
  end

  test "should have default role of member" do
    membership = Membership.new(user: @user, club: @club)
    assert_equal "member", membership.role
  end
end
