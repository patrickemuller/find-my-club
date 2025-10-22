require "test_helper"

class MembershipsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    @owner = create(:user)
    @public_club = create(:club, owner: @owner, public: true)
    @private_club = create(:club, owner: @owner, public: false)
  end

  # Create action (join club)
  test "should require authentication to join club" do
    post club_membership_path(@public_club)
    assert_redirected_to new_user_session_path
  end

  test "should allow user to join public club with active status" do
    sign_in @user

    assert_difference("Membership.count", 1) do
      post club_membership_path(@public_club)
    end

    membership = Membership.last
    assert_equal @user, membership.user
    assert_equal @public_club, membership.club
    assert_equal "active", membership.status
    assert_equal "member", membership.role

    assert_redirected_to @public_club
    assert_equal "You have successfully joined #{@public_club.name}!", flash[:notice]
  end

  test "should allow user to join private club with pending status" do
    sign_in @user

    assert_difference("Membership.count", 1) do
      post club_membership_path(@private_club)
    end

    membership = Membership.last
    assert_equal @user, membership.user
    assert_equal @private_club, membership.club
    assert_equal "pending", membership.status
    assert_equal "member", membership.role

    assert_redirected_to @private_club
    assert_equal "Your request to join #{@private_club.name} is pending approval from the club owner.", flash[:notice]
  end

  test "should not allow owner to join their own club" do
    sign_in @owner

    assert_no_difference("Membership.count") do
      post club_membership_path(@public_club)
    end

    assert_redirected_to @public_club
    assert_equal "You cannot join this club.", flash[:alert]
  end

  test "should not allow user to join same club twice" do
    sign_in @user
    create(:membership, user: @user, club: @public_club)

    assert_no_difference("Membership.count") do
      post club_membership_path(@public_club)
    end

    assert_redirected_to @public_club
    assert_equal "You cannot join this club.", flash[:alert]
  end

  # Destroy action (leave club)
  test "should require authentication to leave club" do
    delete club_membership_path(@public_club)
    assert_redirected_to new_user_session_path
  end

  test "should allow user to leave club" do
    sign_in @user
    membership = create(:membership, user: @user, club: @public_club)

    assert_difference("Membership.count", -1) do
      delete club_membership_path(@public_club)
    end

    assert_redirected_to @public_club
    assert_equal "You have left #{@public_club.name}.", flash[:notice]
  end

  test "should not allow leaving club if not a member" do
    sign_in @user

    assert_no_difference("Membership.count") do
      delete club_membership_path(@public_club)
    end

    assert_redirected_to @public_club
    assert_equal "You are not a member of this club.", flash[:alert]
  end

  test "owner can remove a member via destroy action" do
    sign_in @owner
    member = create(:user)
    membership = create(:membership, user: member, club: @public_club)

    assert_difference("Membership.count", -1) do
      delete club_membership_path(@public_club), params: { membership_id: membership.id }
    end

    assert_redirected_to members_club_path(@public_club)
    assert_equal "Member has been removed from the club.", flash[:notice]
  end

  # Approve action
  test "should require authentication to approve member" do
    membership = create(:membership, :pending, club: @public_club)
    patch approve_club_membership_path(@public_club, membership)
    assert_redirected_to new_user_session_path
  end

  test "should require owner to approve member" do
    sign_in @user
    membership = create(:membership, :pending, club: @public_club)

    patch approve_club_membership_path(@public_club, membership)

    assert_redirected_to @public_club
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end

  test "owner should be able to approve pending member" do
    sign_in @owner
    membership = create(:membership, :pending, club: @public_club)

    patch approve_club_membership_path(@public_club, membership)

    membership.reload
    assert_equal "active", membership.status

    assert_redirected_to members_club_path(@public_club)
    assert_equal "#{membership.user.first_name} has been approved and is now an active member.", flash[:notice]
  end

  test "should send email when member is approved" do
    sign_in @owner
    membership = create(:membership, :pending, club: @public_club)

    assert_enqueued_emails 1 do
      patch approve_club_membership_path(@public_club, membership)
    end
  end

  # Enable action
  test "should require authentication to enable member" do
    membership = create(:membership, :disabled, club: @public_club)
    patch enable_club_membership_path(@public_club, membership)
    assert_redirected_to new_user_session_path
  end

  test "should require owner to enable member" do
    sign_in @user
    membership = create(:membership, :disabled, club: @public_club)

    patch enable_club_membership_path(@public_club, membership)

    assert_redirected_to @public_club
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end

  test "owner should be able to enable disabled member" do
    sign_in @owner
    membership = create(:membership, :disabled, club: @public_club)

    patch enable_club_membership_path(@public_club, membership)

    membership.reload
    assert_equal "active", membership.status

    assert_redirected_to members_club_path(@public_club)
    assert_equal "#{membership.user.first_name} has been enabled.", flash[:notice]
  end

  # Disable action
  test "should require authentication to disable member" do
    membership = create(:membership, club: @public_club)
    patch disable_club_membership_path(@public_club, membership)
    assert_redirected_to new_user_session_path
  end

  test "should require owner to disable member" do
    sign_in @user
    membership = create(:membership, club: @public_club)

    patch disable_club_membership_path(@public_club, membership)

    assert_redirected_to @public_club
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end

  test "owner should be able to disable active member" do
    sign_in @owner
    membership = create(:membership, club: @public_club)

    patch disable_club_membership_path(@public_club, membership)

    membership.reload
    assert_equal "disabled", membership.status

    assert_redirected_to members_club_path(@public_club)
    assert_equal "#{membership.user.first_name} has been disabled.", flash[:notice]
  end
end
