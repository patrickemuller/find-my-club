# == Schema Information
#
# Table name: clubs
#
#  id         :bigint           not null, primary key
#  active     :boolean          default(TRUE)
#  category   :string           not null
#  level      :string           not null
#  name       :string           not null
#  public     :boolean          default(FALSE)
#  slug       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  owner_id   :bigint           not null
#
# Indexes
#
#  index_clubs_on_owner_id  (owner_id)
#  index_clubs_on_slug      (slug) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (owner_id => users.id)
#
require "rails_helper"

RSpec.describe Club, type: :model do
  let(:owner) { create(:user) }
  let(:club) { build(:club, owner: owner) }

  describe "validations" do
    it "is valid with valid attributes" do
      expect(club).to be_valid
    end

    it "requires name" do
      club.name = nil
      expect(club).not_to be_valid
      expect(club.errors[:name]).to include("can't be blank")
    end

    it "requires category" do
      club.category = nil
      expect(club).not_to be_valid
      expect(club.errors[:category]).to include("can't be blank")
    end

    it "requires level" do
      club.level = nil
      expect(club).not_to be_valid
      expect(club.errors[:level]).to include("can't be blank")
    end

    it "requires description" do
      club.description = nil
      expect(club).not_to be_valid
      expect(club.errors[:description]).to include("can't be blank")
    end

    it "requires rules" do
      club.rules = nil
      expect(club).not_to be_valid
      expect(club.errors[:rules]).to include("can't be blank")
    end

    it "validates public is boolean" do
      expect(club).to be_valid
      club.public = true
      expect(club).to be_valid
      club.public = false
      expect(club).to be_valid
    end
  end

  describe "associations" do
    it "belongs to owner" do
      expect(club).to respond_to(:owner)
    end

    it "has many memberships" do
      expect(club).to respond_to(:memberships)
    end

    it "has many members through memberships" do
      expect(club).to respond_to(:members)
    end

    it "has many events" do
      expect(club).to respond_to(:events)
    end

    it "destroys dependent memberships when destroyed" do
      saved_club = create(:club, owner: owner)
      user = create(:user)
      create(:membership, club: saved_club, user: user)

      expect { saved_club.destroy }.to change(Membership, :count).by(-1)
    end

    it "destroys dependent events when destroyed" do
      saved_club = create(:club, owner: owner)
      create(:event, club: saved_club)

      expect { saved_club.destroy }.to change(Event, :count).by(-1)
    end
  end

  describe "FriendlyId" do
    it "generates slug from name" do
      club.name = "Running Club Downtown"
      club.save!
      expect(club.slug).to eq("running-club-downtown")
    end

    it "regenerates slug when name changes" do
      club.save!
      original_slug = club.slug

      club.update(name: "New Club Name")
      expect(club.slug).not_to eq(original_slug)
      expect(club.slug).to eq("new-club-name")
    end

    it "can be found by slug" do
      club.save!
      found_club = Club.friendly.find(club.slug)
      expect(found_club).to eq(club)
    end
  end

  describe "scopes" do
    describe ".publicly_visible" do
      it "returns only public clubs" do
        public_club = create(:club, public: true)
        private_club = create(:club, public: false)

        expect(Club.publicly_visible).to include(public_club)
        expect(Club.publicly_visible).not_to include(private_club)
      end
    end

    describe ".search" do
      it "finds clubs by name case-insensitively" do
        matching_club = create(:club, name: "Running Club")
        create(:club, name: "Swimming Club")

        results = Club.search("running")
        expect(results).to include(matching_club)
        expect(results.count).to eq(1)
      end

      it "returns all clubs when search is blank" do
        create(:club)
        create(:club)

        expect(Club.search("").count).to eq(Club.count)
        expect(Club.search(nil).count).to eq(Club.count)
      end
    end

    describe ".with_category" do
      it "filters clubs by category" do
        team_club = create(:club, category: "team_ball_sports")
        racket_club = create(:club, category: "racket_sports")

        results = Club.with_category([ "team_ball_sports" ])
        expect(results).to include(team_club)
        expect(results).not_to include(racket_club)
      end

      it "returns all clubs when categories is blank" do
        create(:club)
        create(:club)

        expect(Club.with_category(nil).count).to eq(Club.count)
        expect(Club.with_category([]).count).to eq(Club.count)
      end
    end

    describe ".with_level" do
      it "filters clubs by level" do
        beginner_club = create(:club, level: "beginner")
        advanced_club = create(:club, level: "advanced")

        results = Club.with_level("beginner")
        expect(results).to include(beginner_club)
        expect(results).not_to include(advanced_club)
      end

      it "returns all clubs when level is blank" do
        create(:club)
        create(:club)

        expect(Club.with_level(nil).count).to eq(Club.count)
        expect(Club.with_level("").count).to eq(Club.count)
      end
    end
  end

  describe "instance methods" do
    describe "#private?" do
      it "returns true when club is not public" do
        club.public = false
        expect(club).to be_private
      end

      it "returns false when club is public" do
        club.public = true
        expect(club).not_to be_private
      end
    end

    describe "#is_owner?" do
      it "returns true when user is the owner" do
        expect(club.is_owner?(owner)).to be true
      end

      it "returns false when user is not the owner" do
        other_user = create(:user)
        expect(club.is_owner?(other_user)).to be false
      end

      it "returns false when user is nil" do
        expect(club.is_owner?(nil)).to be false
      end
    end

    describe "#disabled?" do
      it "returns true when club is not active" do
        club.active = false
        expect(club).to be_disabled
      end

      it "returns false when club is active" do
        club.active = true
        expect(club).not_to be_disabled
      end
    end

    describe "#formatted_category" do
      it "formats single category" do
        club.category = "team_ball_sports"
        expect(club.formatted_category).to eq("Team Ball Sports")
      end

      it "formats multiple categories" do
        club.category = "team_ball_sports, racket_sports"
        expect(club.formatted_category).to eq("Team Ball Sports, Racket Sports")
      end
    end

    describe "#formatted_level" do
      it "formats single level" do
        club.level = "beginner"
        expect(club.formatted_level).to eq("Beginner")
      end

      it "formats multiple levels" do
        club.level = "beginner, intermediate"
        expect(club.formatted_level).to eq("Beginner, Intermediate")
      end
    end

    describe "#members_count" do
      it "returns count of active members" do
        club.save!
        user1 = create(:user)
        user2 = create(:user)
        user3 = create(:user)

        create(:membership, club: club, user: user1, status: "active")
        create(:membership, club: club, user: user2, status: "active")
        create(:membership, club: club, user: user3, status: "pending")

        expect(club.members_count).to eq(2)
      end

      it "returns 0 when no members" do
        club.save!
        expect(club.members_count).to eq(0)
      end
    end

    describe "#has_member?" do
      let!(:saved_club) { create(:club, owner: owner) }
      let(:member_user) { create(:user) }

      it "returns true when user is an active member" do
        create(:membership, club: saved_club, user: member_user, status: "active")
        expect(saved_club.has_member?(member_user)).to be true
      end

      it "returns false when user is pending member" do
        create(:membership, club: saved_club, user: member_user, status: "pending")
        expect(saved_club.has_member?(member_user)).to be false
      end

      it "returns false when user is disabled member" do
        create(:membership, club: saved_club, user: member_user, status: "disabled")
        expect(saved_club.has_member?(member_user)).to be false
      end

      it "returns false when user is not a member" do
        non_member = create(:user)
        expect(saved_club.has_member?(non_member)).to be false
      end

      it "returns false when user is nil" do
        expect(saved_club.has_member?(nil)).to be false
      end
    end
  end

  describe "default values" do
    it "defaults active to true" do
      new_club = Club.new(name: "Test", category: "team_ball_sports", level: "beginner", owner: owner)
      expect(new_club.active).to be true
    end

    it "defaults public to false" do
      new_club = Club.new(name: "Test", category: "team_ball_sports", level: "beginner", owner: owner)
      expect(new_club.public).to be false
    end
  end
end
