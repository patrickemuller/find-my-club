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
class Membership < ApplicationRecord
  belongs_to :user
  belongs_to :club

  validates :user_id, :club_id, :status, :role, presence: true
  validates :user_id, uniqueness: { scope: :club_id, message: "is already a member of this club" }

  validate :owner_cannot_be_member_of_own_club

  enum :status, { active: "active", pending: "pending", disabled: "disabled" }
  enum :role, { member: "member" }

  private

  def owner_cannot_be_member_of_own_club
    if user_id.present? && club_id.present? && club.owner_id == user_id
      errors.add(:base, "Club owner cannot be a member of it's own club")
    end
  end
end
