# == Schema Information
#
# Table name: club_invitations
#
#  id            :bigint           not null, primary key
#  email         :string           not null
#  expires_at    :datetime         not null
#  status        :string           default("pending"), not null
#  token         :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  club_id       :bigint           not null
#  invited_by_id :bigint           not null
#  user_id       :bigint
#
# Indexes
#
#  index_club_invitations_on_club_id            (club_id)
#  index_club_invitations_on_club_id_and_email  (club_id,email) UNIQUE WHERE ((status)::text = 'pending'::text)
#  index_club_invitations_on_email              (email)
#  index_club_invitations_on_invited_by_id      (invited_by_id)
#  index_club_invitations_on_status             (status)
#  index_club_invitations_on_token              (token) UNIQUE
#  index_club_invitations_on_user_id            (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (club_id => clubs.id)
#  fk_rails_...  (invited_by_id => users.id)
#  fk_rails_...  (user_id => users.id)
#
class ClubInvitation < ApplicationRecord
  belongs_to :club
  belongs_to :invited_by, class_name: "User"
  belongs_to :user, optional: true

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :token, presence: true, uniqueness: true
  validates :status, presence: true
  validates :email, uniqueness: { conditions: -> { pending } }
  validate :user_not_already_member
  validate :not_club_owner

  enum :status, { pending: "pending", accepted: "accepted", rejected: "rejected", expired: "expired" }

  scope :pending, -> { where(status: "pending").where("expires_at > ?", Time.current) }
  scope :for_email, ->(email) { where(email: email.downcase) }
  scope :for_user, ->(user) { where(email: user.email.downcase) }

  before_validation :generate_token, on: :create
  before_validation :set_expiration, on: :create
  before_validation :normalize_email

  def expired?
    expires_at < Time.current
  end

  def can_accept?
    pending? && !expired?
  end

  def accept!(user)
    return false unless can_accept?

    transaction do
      update!(status: "accepted", user: user)
      club.memberships.create!(user: user, status: "active")
    end
  end

  def reject!
    return false unless can_accept?
    update!(status: "rejected")
  end

  private

  def generate_token
    self.token ||= SecureRandom.urlsafe_base64(32)
  end

  def set_expiration
    self.expires_at ||= 48.hours.from_now
  end

  def normalize_email
    self.email = email.downcase.strip if email.present?
  end

  def user_not_already_member
    return unless club && email

    existing_user = User.find_by(email: email.downcase)
    if existing_user && club.has_member?(existing_user)
      errors.add(:email, "is already a member of this club")
    end
  end

  def not_club_owner
    return unless club && email

    if club.owner.email.downcase == email.downcase
      errors.add(:email, "cannot invite the club owner")
    end
  end
end
