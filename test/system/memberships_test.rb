require "application_system_test_case"

class MembershipsTest < ApplicationSystemTestCase
  setup do
    @user = create(:user)
    @owner = create(:user)
    @public_club = create(:club, owner: @owner, public: true, name: "Public Running Club")
    @private_club = create(:club, owner: @owner, public: false, name: "Private Elite Club")
  end

  # Public club membership flow
  test "user can join a public club" do
    sign_in @user
    visit club_path(@public_club)

    assert_selector "button", text: "Join"

    click_button "Join"

    assert_text "You have successfully joined #{@public_club.name}!"
    assert_selector "button", text: "Leave"

    # Verify membership was created
    assert Membership.exists?(user: @user, club: @public_club, status: "active")
  end

  test "join button changes to leave button after joining" do
    sign_in @user
    visit club_path(@public_club)

    assert_selector "button", text: "Join"
    assert_no_selector "button", text: "Leave"

    click_button "Join"

    assert_selector "button", text: "Leave"
    assert_no_selector "button", text: "Join"
  end

  test "user can leave a club" do
    sign_in @user
    create(:membership, user: @user, club: @public_club)

    visit club_path(@public_club)

    assert_selector "button", text: "Leave"

    accept_confirm do
      click_button "Leave"
    end

    assert_text "You have left #{@public_club.name}."
    assert_selector "button", text: "Join"

    # Verify membership was deleted
    assert_not Membership.exists?(user: @user, club: @public_club)
  end

  test "member count updates correctly" do
    sign_in @user
    visit club_path(@public_club)

    # Initially 0 members
    assert_text "0 members"

    click_button "Join"

    # After joining, should show 1 member
    visit club_path(@public_club)
    assert_text "1 member"
  end

  test "pending members don't count toward member count" do
    sign_in @user
    visit club_path(@private_club)

    # Initially 0 members
    assert_text "0 members"

    click_button "Join"

    # After requesting to join (pending), should still show 0 members
    visit club_path(@private_club)
    assert_text "0 members"
  end

  # Private club membership flow
  test "user can request to join a private club" do
    sign_in @user
    visit club_path(@private_club)

    assert_selector "button", text: "Join"

    click_button "Join"

    assert_text "Your request to join #{@private_club.name} is pending approval from the club owner."
    assert_selector "span", text: "Pending Approval"

    # Verify membership was created with pending status
    assert Membership.exists?(user: @user, club: @private_club, status: "pending")
  end

  test "pending members see 'Pending Approval' message" do
    sign_in @user
    create(:membership, :pending, user: @user, club: @private_club)

    visit club_path(@private_club)

    assert_selector "span", text: "Pending Approval"
    assert_no_selector "button", text: "Join"
    assert_no_selector "button", text: "Leave"
  end

  test "disabled members see 'Membership Disabled' message" do
    sign_in @user
    create(:membership, :disabled, user: @user, club: @public_club)

    visit club_path(@public_club)

    assert_selector "span", text: "Membership Disabled"
    assert_no_selector "button", text: "Join"
    assert_no_selector "button", text: "Leave"
  end

  # Authorization tests
  test "owner cannot join their own club" do
    sign_in @owner
    visit club_path(@public_club)

    assert_selector "a", text: "Update my Club"
    assert_no_selector "button", text: "Join"
  end

  test "user cannot join same club twice" do
    sign_in @user
    create(:membership, user: @user, club: @public_club)

    visit club_path(@public_club)

    assert_selector "button", text: "Leave"
    assert_no_selector "button", text: "Join"
  end

  test "non-authenticated users see sign in to join" do
    visit club_path(@public_club)

    assert_selector "a", text: "Sign in to Join"
    assert_no_selector "button", text: "Join"
  end

  # Owner member management
  test "owner can approve pending memberships" do
    sign_in @owner
    member = create(:user, first_name: "Jane")
    membership = create(:membership, :pending, user: member, club: @private_club)

    visit members_club_path(@private_club)

    within "section", text: "Pending Approval" do
      assert_text "Jane"
      click_button "Approve"
    end

    assert_text "Jane has been approved and is now an active member."

    # Verify membership status changed
    membership.reload
    assert_equal "active", membership.status
  end

  test "owner can disable active members" do
    sign_in @owner
    member = create(:user, first_name: "John")
    membership = create(:membership, user: member, club: @public_club)

    visit members_club_path(@public_club)

    within "section", text: "Active Members" do
      assert_text "John"
      accept_confirm do
        click_button "Disable"
      end
    end

    assert_text "John has been disabled."

    # Verify membership status changed
    membership.reload
    assert_equal "disabled", membership.status
  end

  test "owner can enable disabled members" do
    sign_in @owner
    member = create(:user, first_name: "Bob")
    membership = create(:membership, :disabled, user: member, club: @public_club)

    visit members_club_path(@public_club)

    within "section", text: "Disabled Members" do
      assert_text "Bob"
      click_button "Enable"
    end

    assert_text "Bob has been enabled."

    # Verify membership status changed
    membership.reload
    assert_equal "active", membership.status
  end

  test "owner can remove members" do
    sign_in @owner
    member = create(:user, first_name: "Sarah")
    membership = create(:membership, user: member, club: @public_club)

    visit members_club_path(@public_club)

    within "section", text: "Active Members" do
      assert_text "Sarah"
      accept_confirm do
        click_button "Remove"
      end
    end

    assert_text "Member has been removed from the club."

    # Verify membership was deleted
    assert_not Membership.exists?(id: membership.id)
  end

  test "owner can view all members categorized by status" do
    sign_in @owner
    active_member = create(:user, first_name: "Alice")
    pending_member = create(:user, first_name: "Charlie")
    disabled_member = create(:user, first_name: "Dave")

    create(:membership, user: active_member, club: @public_club, status: "active")
    create(:membership, :pending, user: pending_member, club: @public_club)
    create(:membership, :disabled, user: disabled_member, club: @public_club)

    visit members_club_path(@public_club)

    within "section", text: "Active Members" do
      assert_text "Alice"
      assert_no_text "Charlie"
      assert_no_text "Dave"
    end

    within "section", text: "Pending Approval" do
      assert_text "Charlie"
      assert_no_text "Alice"
      assert_no_text "Dave"
    end

    within "section", text: "Disabled Members" do
      assert_text "Dave"
      assert_no_text "Alice"
      assert_no_text "Charlie"
    end
  end

  # My Clubs page tests
  test "user can view clubs they own and clubs they are member of" do
    sign_in @user
    owned_club = create(:club, owner: @user, name: "My Owned Club")
    member_club = create(:club, name: "Member Club")
    create(:membership, user: @user, club: member_club)

    visit my_clubs_path

    within "section", text: "Clubs I Own" do
      assert_text "My Owned Club"
      assert_no_text "Member Club"
    end

    within "section", text: "Clubs I'm a Member Of" do
      assert_text "Member Club"
      assert_no_text "My Owned Club"
    end
  end

  test "user can leave club from my clubs page" do
    sign_in @user
    member_club = create(:club, name: "Test Club")
    create(:membership, user: @user, club: member_club)

    visit my_clubs_path

    within "section", text: "Clubs I'm a Member Of" do
      assert_text "Test Club"
      accept_confirm do
        click_button "Leave"
      end
    end

    assert_text "You have left Test Club."
  end
end
