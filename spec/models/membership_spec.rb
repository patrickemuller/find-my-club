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
require "rails_helper"

RSpec.describe Membership, type: :model do
  let(:user) { create(:user) }
  let(:club) { create(:club) }
  let(:membership) { build(:membership, user: user, club: club) }

  describe "validations" do
    it "is valid with valid attributes" do
      expect(membership).to be_valid
    end

    it "requires user_id" do
      membership.user = nil
      expect(membership).not_to be_valid
      expect(membership.errors[:user_id]).to include("can't be blank")
    end

    it "requires club_id" do
      membership.club = nil
      expect(membership).not_to be_valid
      expect(membership.errors[:club_id]).to include("can't be blank")
    end

    it "requires status" do
      membership.status = nil
      expect(membership).not_to be_valid
      expect(membership.errors[:status]).to include("can't be blank")
    end

    it "requires role" do
      membership.role = nil
      expect(membership).not_to be_valid
      expect(membership.errors[:role]).to include("can't be blank")
    end

    it "validates uniqueness of user_id scoped to club_id" do
      membership.save!
      duplicate = build(:membership, user: user, club: club)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to include("is already a member of this club")
    end

    it "allows same user to join different clubs" do
      membership.save!
      other_club = create(:club)
      other_membership = build(:membership, user: user, club: other_club)
      expect(other_membership).to be_valid
    end

    it "allows different users to join same club" do
      membership.save!
      other_user = create(:user)
      other_membership = build(:membership, user: other_user, club: club)
      expect(other_membership).to be_valid
    end

    it "validates status is in allowed values" do
      expect {
        membership.status = "invalid_status"
      }.to raise_error(ArgumentError)
    end

    it "validates role is in allowed values" do
      expect {
        membership.role = "invalid_role"
      }.to raise_error(ArgumentError)
    end

    it "does not allow owner to be a member of their own club" do
      owner = club.owner
      owner_membership = build(:membership, user: owner, club: club)
      expect(owner_membership).not_to be_valid
      expect(owner_membership.errors[:base]).to include("Club owner cannot be a member of it's own club")
    end
  end

  describe "enums" do
    it "has active status enum" do
      membership.status = "active"
      expect(membership).to be_active
    end

    it "has pending status enum" do
      membership.status = "pending"
      expect(membership).to be_pending
    end

    it "has disabled status enum" do
      membership.status = "disabled"
      expect(membership).to be_disabled
    end

    it "has member role enum" do
      membership.role = "member"
      expect(membership).to be_member
    end
  end

  describe "scopes" do
    it "has active scope" do
      active_membership = create(:membership, status: "active")
      pending_membership = create(:membership, :pending)

      expect(Membership.active).to include(active_membership)
      expect(Membership.active).not_to include(pending_membership)
    end

    it "has pending scope" do
      active_membership = create(:membership, status: "active")
      pending_membership = create(:membership, :pending)

      expect(Membership.pending).to include(pending_membership)
      expect(Membership.pending).not_to include(active_membership)
    end

    it "has disabled scope" do
      active_membership = create(:membership, status: "active")
      disabled_membership = create(:membership, :disabled)

      expect(Membership.disabled).to include(disabled_membership)
      expect(Membership.disabled).not_to include(active_membership)
    end
  end

  describe "associations" do
    it "belongs to user" do
      expect(membership).to respond_to(:user)
    end

    it "belongs to club" do
      expect(membership).to respond_to(:club)
    end
  end

  describe "default values" do
    it "has default status of active" do
      new_membership = Membership.new(user: user, club: club)
      expect(new_membership.status).to eq("active")
    end

    it "has default role of member" do
      new_membership = Membership.new(user: user, club: club)
      expect(new_membership.role).to eq("member")
    end
  end
end
