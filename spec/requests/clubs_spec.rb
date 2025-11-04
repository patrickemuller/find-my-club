require "rails_helper"

RSpec.describe "Clubs", type: :request do
  let(:user) { create(:user) }
  let(:owner) { create(:user) }
  let(:club) { create(:club, owner: owner) }

  describe "GET /my_clubs" do
    context "when not authenticated" do
      it "redirects to sign in" do
        get my_clubs_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated" do
      before { login_as user }

      it "returns successful response" do
        get my_clubs_path
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "GET /clubs/:id/members" do
    context "when not authenticated" do
      it "redirects to sign in" do
        get members_club_path(club)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated as non-owner" do
      before { login_as user }

      it "returns not found" do
        get members_club_path(club)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when authenticated as owner" do
      before { login_as owner }

      it "returns successful response" do
        get members_club_path(club)
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "PATCH /clubs/:id/enable" do
    before { club.update(active: false) }

    context "when not authenticated" do
      it "redirects to sign in" do
        patch enable_club_path(club)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated as non-owner" do
      before { login_as user }

      it "returns not found" do
        patch enable_club_path(club)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when authenticated as owner" do
      before { login_as owner }

      it "enables the club" do
        expect {
          patch enable_club_path(club)
          club.reload
        }.to change { club.active }.from(false).to(true)
      end

      it "redirects to my clubs with success message" do
        patch enable_club_path(club)
        expect(response).to redirect_to(my_clubs_path)
        expect(flash[:notice]).to eq("Club was successfully enabled.")
      end
    end
  end

  describe "PATCH /clubs/:id/disable" do
    context "when not authenticated" do
      it "redirects to sign in" do
        patch disable_club_path(club)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated as non-owner" do
      before { login_as user }

      it "returns not found" do
        patch disable_club_path(club)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when authenticated as owner" do
      before { login_as owner }

      it "disables the club" do
        expect {
          patch disable_club_path(club)
          club.reload
        }.to change { club.active }.from(true).to(false)
      end

      it "redirects to my clubs with success message" do
        patch disable_club_path(club)
        expect(response).to redirect_to(my_clubs_path)
        expect(flash[:notice]).to eq("Club was successfully disabled.")
      end
    end
  end
end
