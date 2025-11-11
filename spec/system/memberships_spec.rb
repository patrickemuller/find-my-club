require "rails_helper"

RSpec.describe "Memberships", type: :system do
  let(:user) { create(:user) }
  let(:owner) { create(:user) }
  let(:public_club) { create(:club, owner: owner, public: true, name: "Public Running Club") }
  let(:private_club) { create(:club, owner: owner, public: false, name: "Private Elite Club") }

  # Public club membership flow
  describe "Public club membership" do
    it "allows user to join a public club" do
      login_as user
      visit club_path(public_club)

      expect(page).to have_button("Join")

      click_button "Join"

      expect(page).to have_text("You have successfully joined #{public_club.name}!")
      expect(page).to have_button("Leave")

      # Verify membership was created
      expect(Membership.exists?(user: user, club: public_club, status: "active")).to be true
    end

    it "changes join button to leave button after joining" do
      login_as user
      visit club_path(public_club)

      expect(page).to have_button("Join")
      expect(page).not_to have_button("Leave")

      click_button "Join"

      expect(page).to have_button("Leave")
      expect(page).not_to have_button("Join")
    end

    it "allows user to leave a club" do
      login_as user
      create(:membership, user: user, club: public_club)

      visit club_path(public_club)

      expect(page).to have_button("Leave")

      accept_confirm do
        click_button "Leave"
      end

      expect(page).to have_text("You have left #{public_club.name}.")
      expect(page).to have_button("Join")

      # Verify membership was deleted
      expect(Membership.exists?(user: user, club: public_club)).to be false
    end

    it "updates member count correctly" do
      login_as user
      visit club_path(public_club)

      # Initially 0 members
      expect(page).to have_text("0 members")

      click_button "Join"

      # After joining, should show 1 member
      visit club_path(public_club)
      expect(page).to have_text("1 member")
    end

    it "does not count pending members in member count" do
      login_as user
      visit club_path(private_club)

      # Initially 0 members
      expect(page).to have_text("0 members")

      click_button "Join"

      # After requesting to join (pending), should still show 0 members
      visit club_path(private_club)
      expect(page).to have_text("0 members")
    end
  end

  # Private club membership flow
  describe "Private club membership" do
    it "allows user to request to join a private club" do
      login_as user
      visit club_path(private_club)

      expect(page).to have_button("Join")

      click_button "Join"

      expect(page).to have_text("Your request to join #{private_club.name} is pending approval from the club owner.")
      expect(page).to have_selector("span", text: "Pending Approval")

      # Verify membership was created with pending status
      expect(Membership.exists?(user: user, club: private_club, status: "pending")).to be true
    end

    it "shows 'Pending Approval' message for pending members" do
      login_as user
      create(:membership, :pending, user: user, club: private_club)

      visit club_path(private_club)

      expect(page).to have_selector("span", text: "Pending Approval")
      expect(page).not_to have_button("Join")
      expect(page).not_to have_button("Leave")
    end

    it "shows 'Membership Disabled' message for disabled members" do
      login_as user
      create(:membership, :disabled, user: user, club: public_club)

      visit club_path(public_club)

      expect(page).to have_selector("span", text: "Membership Disabled")
      expect(page).not_to have_button("Join")
      expect(page).not_to have_button("Leave")
    end
  end

  # Authorization tests
  describe "Authorization" do
    it "does not allow owner to join their own club" do
      login_as owner
      visit club_path(public_club)

      expect(page).to have_link("Update my Club")
      expect(page).not_to have_button("Join")
    end

    it "prevents user from joining same club twice" do
      login_as user
      create(:membership, user: user, club: public_club)

      visit club_path(public_club)

      expect(page).to have_button("Leave")
      expect(page).not_to have_button("Join")
    end

    it "shows sign in link for non-authenticated users" do
      visit club_path(public_club)

      expect(page).to have_link("Sign in to Join")
      expect(page).not_to have_button("Join")
    end
  end

  # Owner member management
  describe "Owner member management" do
    it "allows owner to approve pending memberships" do
      login_as owner
      member = create(:user, first_name: "Jane")
      membership = create(:membership, :pending, user: member, club: private_club)

      visit members_club_path(private_club)

      # Click on the Pending Approval tab
      click_link "Pending Approval"

      within "#pending-content" do
        expect(page).to have_text("Jane")
        click_button "Approve"
      end

      expect(page).to have_text("Jane has been approved and is now an active member.")

      # Verify membership status changed
      membership.reload
      expect(membership.status).to eq("active")
    end

    it "allows owner to disable active members" do
      login_as owner
      member = create(:user, first_name: "John")
      membership = create(:membership, user: member, club: public_club)

      visit members_club_path(public_club)

      # Active tab should be selected by default
      within "#active-content" do
        expect(page).to have_text("John")
        accept_confirm do
          click_button "Disable"
        end
      end

      expect(page).to have_text("John has been disabled.")

      # Verify membership status changed
      membership.reload
      expect(membership.status).to eq("disabled")
    end

    it "allows owner to enable disabled members" do
      login_as owner
      member = create(:user, first_name: "Bob")
      membership = create(:membership, :disabled, user: member, club: public_club)

      visit members_club_path(public_club)

      # Click on the Disabled tab
      click_link "Disabled"

      within "#disabled-content" do
        expect(page).to have_text("Bob")
        click_button "Enable"
      end

      expect(page).to have_text("Bob has been enabled.")

      # Verify membership status changed
      membership.reload
      expect(membership.status).to eq("active")
    end

    it "allows owner to remove members" do
      login_as owner
      member = create(:user, first_name: "Sarah")
      membership = create(:membership, user: member, club: public_club)

      visit members_club_path(public_club)

      # Active tab should be selected by default
      within "#active-content" do
        expect(page).to have_text("Sarah")
        accept_confirm do
          click_button "Remove"
        end
      end

      expect(page).to have_text("Member has been removed from the club.")

      # Verify membership was deleted
      expect(Membership.exists?(id: membership.id)).to be false
    end

    it "allows owner to view all members categorized by status" do
      login_as owner
      active_member = create(:user, first_name: "Alice")
      pending_member = create(:user, first_name: "Charlie")
      disabled_member = create(:user, first_name: "Dave")

      create(:membership, user: active_member, club: public_club, status: "active")
      create(:membership, :pending, user: pending_member, club: public_club)
      create(:membership, :disabled, user: disabled_member, club: public_club)

      visit members_club_path(public_club)

      # Check Active tab (default)
      within "#active-content" do
        expect(page).to have_text("Alice")
        expect(page).not_to have_text("Charlie")
        expect(page).not_to have_text("Dave")
      end

      # Click on Pending Approval tab and check
      click_link "Pending Approval"
      within "#pending-content" do
        expect(page).to have_text("Charlie")
        expect(page).not_to have_text("Alice")
        expect(page).not_to have_text("Dave")
      end

      # Click on Disabled tab and check
      click_link "Disabled"
      within "#disabled-content" do
        expect(page).to have_text("Dave")
        expect(page).not_to have_text("Alice")
        expect(page).not_to have_text("Charlie")
      end
    end
  end

  # My Clubs page tests
  describe "My Clubs page" do
    it "shows clubs user owns and clubs user is member of" do
      login_as user
      owned_club = create(:club, owner: user, name: "My Owned Club")
      member_club = create(:club, name: "Member Club")
      create(:membership, user: user, club: member_club)

      visit my_clubs_path

      within "section", text: "Clubs I Own" do
        expect(page).to have_text("My Owned Club")
        expect(page).not_to have_text("Member Club")
      end

      within "section", text: "Clubs I'm a Member Of" do
        expect(page).to have_text("Member Club")
        expect(page).not_to have_text("My Owned Club")
      end
    end

    it "allows user to leave club from my clubs page" do
      login_as user
      member_club = create(:club, name: "Test Club")
      create(:membership, user: user, club: member_club)

      visit my_clubs_path

      within "section", text: "Clubs I'm a Member Of" do
        expect(page).to have_text("Test Club")
        accept_confirm do
          click_button "Leave"
        end
      end

      expect(page).to have_text("You have left Test Club.")
    end
  end
end
