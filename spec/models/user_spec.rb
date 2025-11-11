# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  admin                  :boolean          default(FALSE)
#  athlinks_url           :string
#  confirmation_sent_at   :datetime
#  confirmation_token     :string
#  confirmed_at           :datetime
#  current_sign_in_at     :datetime
#  current_sign_in_ip     :string
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  first_name             :string           not null
#  last_name              :string           not null
#  last_sign_in_at        :datetime
#  last_sign_in_ip        :string
#  outside_url            :string
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  sign_in_count          :integer          default(0), not null
#  strava_url             :string
#  trailforks_url         :string
#  unconfirmed_email      :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_users_on_confirmation_token    (confirmation_token) UNIQUE
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#
require "rails_helper"

RSpec.describe User, type: :model do
  let(:user) { build(:user) }

  describe "validations" do
    it "is valid with valid attributes" do
      expect(user).to be_valid
    end

    it "requires first_name" do
      user.first_name = nil
      expect(user).not_to be_valid
      expect(user.errors[:first_name]).to include("can't be blank")
    end

    it "requires last_name" do
      user.last_name = nil
      expect(user).not_to be_valid
      expect(user.errors[:last_name]).to include("can't be blank")
    end

    it "requires email" do
      user.email = nil
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("can't be blank")
    end

    it "requires unique email" do
      existing_user = create(:user, email: "test@example.com")
      user.email = "test@example.com"
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("has already been taken")
    end

    it "requires valid email format" do
      user.email = "invalid_email"
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("is invalid")
    end

    it "requires password" do
      user.password = nil
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("can't be blank")
    end

    it "requires password to be at least 8 characters" do
      user.password = "1234567"
      user.password_confirmation = "1234567"
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("is too short (minimum is 8 characters)")
    end
  end

  describe "associations" do
    it "has many clubs as owner" do
      user.save!
      expect(user).to respond_to(:clubs)
    end

    it "has many memberships" do
      user.save!
      expect(user).to respond_to(:memberships)
    end

    it "has many clubs_as_member through memberships" do
      user.save!
      expect(user).to respond_to(:clubs_as_member)
    end

    it "destroys dependent clubs when destroyed" do
      user.save!
      club = create(:club, owner: user)

      expect { user.destroy }.to change(Club, :count).by(-1)
    end

    it "destroys dependent memberships when destroyed" do
      user.save!
      club = create(:club)
      create(:membership, user: user, club: club)

      expect { user.destroy }.to change(Membership, :count).by(-1)
    end
  end

  describe "default values" do
    it "defaults admin to false" do
      new_user = User.new
      expect(new_user.admin).to eq(false)
    end

    it "defaults sign_in_count to 0" do
      new_user = User.new
      expect(new_user.sign_in_count).to eq(0)
    end
  end

  describe "#member_of?" do
    let(:club) { create(:club) }

    it "returns true when user is an active member" do
      user.save!
      create(:membership, user: user, club: club, status: "active")
      expect(user.member_of?(club)).to be true
    end

    it "returns false when user is a pending member" do
      user.save!
      create(:membership, :pending, user: user, club: club)
      expect(user.member_of?(club)).to be false
    end

    it "returns false when user is a disabled member" do
      user.save!
      create(:membership, :disabled, user: user, club: club)
      expect(user.member_of?(club)).to be false
    end

    it "returns false when user is not a member" do
      user.save!
      expect(user.member_of?(club)).to be false
    end
  end

  describe "#can_join?" do
    let(:owner) { create(:user) }
    let(:club) { create(:club, owner: owner) }

    it "returns true when user can join the club" do
      user.save!
      expect(user.can_join?(club)).to be true
    end

    it "returns false when user is the owner" do
      expect(owner.can_join?(club)).to be false
    end

    it "returns false when user already has active membership" do
      user.save!
      create(:membership, user: user, club: club, status: "active")
      expect(user.can_join?(club)).to be false
    end

    it "returns false when user has pending membership" do
      user.save!
      create(:membership, :pending, user: user, club: club)
      expect(user.can_join?(club)).to be false
    end

    it "returns false when user has disabled membership" do
      user.save!
      create(:membership, :disabled, user: user, club: club)
      expect(user.can_join?(club)).to be false
    end
  end

  describe "Devise modules" do
    it "has database_authenticatable module" do
      expect(user).to respond_to(:valid_password?)
    end

    it "has registerable module" do
      expect(User).to respond_to(:new_with_session)
    end

    it "has recoverable module" do
      expect(user).to respond_to(:send_reset_password_instructions)
    end

    it "has rememberable module" do
      expect(user).to respond_to(:remember_me!)
    end

    it "has confirmable module" do
      expect(user).to respond_to(:confirm)
    end

    it "has trackable module" do
      expect(user).to respond_to(:current_sign_in_at)
      expect(user).to respond_to(:sign_in_count)
    end
  end

  describe "social media username extraction" do
    let(:user) { build(:user) }

    describe "#strava_username" do
      it "extracts username from Strava URL" do
        user.strava_url = "https://www.strava.com/athletes/12004453"
        expect(user.strava_username).to eq("12004453")
      end

      it "handles URLs with trailing slash" do
        user.strava_url = "https://www.strava.com/athletes/12004453/"
        expect(user.strava_username).to eq("12004453")
      end

      it "handles URLs with trailing slash and PROS as url path" do
        user.strava_url = "https://www.strava.com/pros/12004453/"
        expect(user.strava_username).to eq("12004453")
      end

      it "returns nil if URL is blank" do
        user.strava_url = nil
        expect(user.strava_username).to be_nil
      end
    end

    describe "#trailforks_username" do
      it "extracts username from Trailforks URL" do
        user.trailforks_url = "https://www.trailforks.com/profile/patrickemuller/"
        expect(user.trailforks_username).to eq("patrickemuller")
      end

      it "handles URLs without trailing slash" do
        user.trailforks_url = "https://www.trailforks.com/profile/johndoe"
        expect(user.trailforks_username).to eq("johndoe")
      end

      it "returns nil if URL is blank" do
        user.trailforks_url = nil
        expect(user.trailforks_username).to be_nil
      end
    end

    describe "#outside_username" do
      it "extracts username from Outside URL" do
        user.outside_url = "https://www.outsideinc.com/developer"
        expect(user.outside_username).to eq("developer")
      end

      it "extracts last path segment" do
        user.outside_url = "https://www.outsideinc.com/users/johndoe"
        expect(user.outside_username).to eq("johndoe")
      end

      it "returns nil if URL is blank" do
        user.outside_url = nil
        expect(user.outside_username).to be_nil
      end
    end

    describe "#athlinks_username" do
      it "extracts username from Athlinks URL" do
        user.athlinks_url = "https://www.athlinks.com/athletes/12345"
        expect(user.athlinks_username).to eq("12345")
      end

      it "handles URLs with trailing slash" do
        user.athlinks_url = "https://www.athlinks.com/athletes/67890/"
        expect(user.athlinks_username).to eq("67890")
      end

      it "returns nil if URL is blank" do
        user.athlinks_url = nil
        expect(user.athlinks_username).to be_nil
      end
    end
  end
end
