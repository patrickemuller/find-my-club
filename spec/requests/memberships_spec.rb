require "rails_helper"

RSpec.describe "Memberships", type: :request do
  let(:user) { create(:user) }
  let(:owner) { create(:user) }
  let(:public_club) { create(:club, owner: owner, public: true) }
  let(:private_club) { create(:club, owner: owner, public: false) }

  describe "POST /clubs/:club_id/membership" do
    context "when not authenticated" do
      it "redirects to sign in" do
        post club_membership_path(public_club)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when joining a public club" do
      before { sign_in user }

      it "creates membership with active status" do
        expect {
          post club_membership_path(public_club)
        }.to change(Membership, :count).by(1)

        membership = Membership.last
        expect(membership.user).to eq(user)
        expect(membership.club).to eq(public_club)
        expect(membership.status).to eq("active")
        expect(membership.role).to eq("member")
      end

      it "redirects to club with success message" do
        post club_membership_path(public_club)
        expect(response).to redirect_to(public_club)
        expect(flash[:notice]).to eq("You have successfully joined #{public_club.name}!")
      end
    end

    context "when joining a private club" do
      before { sign_in user }

      it "creates membership with pending status" do
        expect {
          post club_membership_path(private_club)
        }.to change(Membership, :count).by(1)

        membership = Membership.last
        expect(membership.user).to eq(user)
        expect(membership.club).to eq(private_club)
        expect(membership.status).to eq("pending")
        expect(membership.role).to eq("member")
      end

      it "redirects to club with pending message" do
        post club_membership_path(private_club)
        expect(response).to redirect_to(private_club)
        expect(flash[:notice]).to eq("Your request to join #{private_club.name} is pending approval from the club owner.")
      end
    end

    context "when owner tries to join own club" do
      before { sign_in owner }

      it "does not create membership" do
        expect {
          post club_membership_path(public_club)
        }.not_to change(Membership, :count)
      end

      it "redirects with error message" do
        post club_membership_path(public_club)
        expect(response).to redirect_to(public_club)
        expect(flash[:alert]).to eq("You cannot join this club.")
      end
    end

    context "when user tries to join same club twice" do
      before do
        sign_in user
        create(:membership, user: user, club: public_club)
      end

      it "does not create duplicate membership" do
        expect {
          post club_membership_path(public_club)
        }.not_to change(Membership, :count)
      end

      it "redirects with error message" do
        post club_membership_path(public_club)
        expect(response).to redirect_to(public_club)
        expect(flash[:alert]).to eq("You cannot join this club.")
      end
    end
  end

  describe "DELETE /clubs/:club_id/membership" do
    context "when not authenticated" do
      it "redirects to sign in" do
        delete club_membership_path(public_club)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user leaves club" do
      before do
        sign_in user
        create(:membership, user: user, club: public_club)
      end

      it "deletes membership" do
        expect {
          delete club_membership_path(public_club)
        }.to change(Membership, :count).by(-1)
      end

      it "redirects to club with success message" do
        delete club_membership_path(public_club)
        expect(response).to redirect_to(public_club)
        expect(flash[:notice]).to eq("You have left #{public_club.name}.")
      end
    end

    context "when user is not a member" do
      before { sign_in user }

      it "does not change membership count" do
        expect {
          delete club_membership_path(public_club)
        }.not_to change(Membership, :count)
      end

      it "redirects with error message" do
        delete club_membership_path(public_club)
        expect(response).to redirect_to(public_club)
        expect(flash[:alert]).to eq("You are not a member of this club.")
      end
    end

    context "when owner removes a member" do
      let(:member) { create(:user) }
      let!(:membership) { create(:membership, user: member, club: public_club) }

      before { sign_in owner }

      it "removes the member" do
        expect {
          delete club_membership_path(public_club), params: { membership_id: membership.id }
        }.to change(Membership, :count).by(-1)
      end

      it "redirects to members page with success message" do
        delete club_membership_path(public_club), params: { membership_id: membership.id }
        expect(response).to redirect_to(members_club_path(public_club))
        expect(flash[:notice]).to eq("Member has been removed from the club.")
      end
    end
  end

  describe "PATCH /clubs/:club_id/memberships/:id/approve" do
    let(:membership) { create(:membership, :pending, club: public_club) }

    context "when not authenticated" do
      it "redirects to sign in" do
        patch approve_club_membership_path(public_club, membership)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated as non-owner" do
      before { sign_in user }

      it "redirects with authorization error" do
        patch approve_club_membership_path(public_club, membership)
        expect(response).to redirect_to(public_club)
        expect(flash[:alert]).to eq("You are not authorized to perform this action.")
      end
    end

    context "when authenticated as owner" do
      before { sign_in owner }

      it "approves the member" do
        expect {
          patch approve_club_membership_path(public_club, membership)
          membership.reload
        }.to change { membership.status }.from("pending").to("active")
      end

      it "redirects to members page with success message" do
        patch approve_club_membership_path(public_club, membership)
        expect(response).to redirect_to(members_club_path(public_club))
        expect(flash[:notice]).to eq("#{membership.user.first_name} has been approved and is now an active member.")
      end

      it "sends approval email" do
        expect {
          patch approve_club_membership_path(public_club, membership)
        }.to have_enqueued_email
      end
    end
  end

  describe "PATCH /clubs/:club_id/memberships/:id/enable" do
    let(:membership) { create(:membership, :disabled, club: public_club) }

    context "when not authenticated" do
      it "redirects to sign in" do
        patch enable_club_membership_path(public_club, membership)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated as non-owner" do
      before { sign_in user }

      it "redirects with authorization error" do
        patch enable_club_membership_path(public_club, membership)
        expect(response).to redirect_to(public_club)
        expect(flash[:alert]).to eq("You are not authorized to perform this action.")
      end
    end

    context "when authenticated as owner" do
      before { sign_in owner }

      it "enables the member" do
        expect {
          patch enable_club_membership_path(public_club, membership)
          membership.reload
        }.to change { membership.status }.from("disabled").to("active")
      end

      it "redirects to members page with success message" do
        patch enable_club_membership_path(public_club, membership)
        expect(response).to redirect_to(members_club_path(public_club))
        expect(flash[:notice]).to eq("#{membership.user.first_name} has been enabled.")
      end
    end
  end

  describe "PATCH /clubs/:club_id/memberships/:id/disable" do
    let(:membership) { create(:membership, club: public_club) }

    context "when not authenticated" do
      it "redirects to sign in" do
        patch disable_club_membership_path(public_club, membership)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated as non-owner" do
      before { sign_in user }

      it "redirects with authorization error" do
        patch disable_club_membership_path(public_club, membership)
        expect(response).to redirect_to(public_club)
        expect(flash[:alert]).to eq("You are not authorized to perform this action.")
      end
    end

    context "when authenticated as owner" do
      before { sign_in owner }

      it "disables the member" do
        expect {
          patch disable_club_membership_path(public_club, membership)
          membership.reload
        }.to change { membership.status }.from("active").to("disabled")
      end

      it "redirects to members page with success message" do
        patch disable_club_membership_path(public_club, membership)
        expect(response).to redirect_to(members_club_path(public_club))
        expect(flash[:notice]).to eq("#{membership.user.first_name} has been disabled.")
      end
    end
  end
end
