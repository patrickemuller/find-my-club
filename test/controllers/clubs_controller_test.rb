require "test_helper"

class ClubsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    @owner = create(:user)
    @club = create(:club, owner: @owner)
  end

  # My Clubs action
  test "should require authentication for my_clubs" do
    get my_clubs_path
    assert_redirected_to new_user_session_path
  end

  test "my_clubs should load owned clubs" do
    sign_in @user
    owned_club = create(:club, owner: @user)

    get my_clubs_path

    assert_response :success
    assert_includes assigns(:clubs), owned_club
  end

  test "my_clubs should load clubs where user is a member" do
    sign_in @user
    club = create(:club)
    membership = create(:membership, user: @user, club: club)

    get my_clubs_path

    assert_response :success
    assert_includes assigns(:memberships), club
  end

  test "my_clubs should only load active memberships" do
    sign_in @user
    active_club = create(:club)
    pending_club = create(:club)
    disabled_club = create(:club)

    create(:membership, user: @user, club: active_club, status: "active")
    create(:membership, :pending, user: @user, club: pending_club)
    create(:membership, :disabled, user: @user, club: disabled_club)

    get my_clubs_path

    assert_response :success
    assert_includes assigns(:memberships), active_club
    assert_not_includes assigns(:memberships), pending_club
    assert_not_includes assigns(:memberships), disabled_club
  end

  # Members action
  test "should require authentication for members" do
    get members_club_path(@club)
    assert_redirected_to new_user_session_path
  end

  test "should require ownership to view members" do
    sign_in @user

    get members_club_path(@club)
    assert_response :not_found
  end

  test "owner should be able to view members" do
    sign_in @owner

    active_member = create(:user)
    pending_member = create(:user)
    disabled_member = create(:user)

    active_membership = create(:membership, user: active_member, club: @club, status: "active")
    pending_membership = create(:membership, :pending, user: pending_member, club: @club)
    disabled_membership = create(:membership, :disabled, user: disabled_member, club: @club)

    get members_club_path(@club)

    assert_response :success
    assert_includes assigns(:active_members), active_membership
    assert_includes assigns(:pending_members), pending_membership
    assert_includes assigns(:disabled_members), disabled_membership
  end

  # Enable/Disable club actions
  test "should require authentication to enable club" do
    @club.update(active: false)
    patch enable_club_path(@club)
    assert_redirected_to new_user_session_path
  end

  test "should require ownership to enable club" do
    sign_in @user
    @club.update(active: false)

    patch enable_club_path(@club)
    assert_response :not_found
  end

  test "owner should be able to enable club" do
    sign_in @owner
    @club.update(active: false)

    patch enable_club_path(@club)

    @club.reload
    assert @club.active

    assert_redirected_to my_clubs_path
    assert_equal "Club was successfully enabled.", flash[:notice]
  end

  test "should require authentication to disable club" do
    patch disable_club_path(@club)
    assert_redirected_to new_user_session_path
  end

  test "should require ownership to disable club" do
    sign_in @user

    patch disable_club_path(@club)
    assert_response :not_found
  end

  test "owner should be able to disable club" do
    sign_in @owner

    patch disable_club_path(@club)

    @club.reload
    assert_not @club.active

    assert_redirected_to my_clubs_path
    assert_equal "Club was successfully disabled.", flash[:notice]
  end
end
