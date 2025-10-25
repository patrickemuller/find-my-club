# == Schema Information
#
# Table name: event_registrations
#
#  id         :bigint           not null, primary key
#  status     :string           default("confirmed"), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  event_id   :bigint           not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_event_registrations_on_event_id              (event_id)
#  index_event_registrations_on_user_id               (user_id)
#  index_event_registrations_on_user_id_and_event_id  (user_id,event_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (event_id => events.id)
#  fk_rails_...  (user_id => users.id)
#
class EventRegistration < ApplicationRecord
  belongs_to :event
  belongs_to :user

  enum :status, { confirmed: "confirmed", waitlist: "waitlist" }

  validates :event_id, :user_id, :status, presence: true
  validates :user_id, uniqueness: { scope: :event_id, message: "already registered for this event" }
  validate :user_is_club_member
  validate :owner_cannot_register

  scope :confirmed, -> { where(status: "confirmed") }
  scope :waitlist, -> { where(status: "waitlist") }

  private

  def user_is_club_member
    return if user.blank? || event.blank?
    unless event.club.has_member?(user) || event.club.is_owner?(user)
      errors.add(:base, "Only club members can register for events")
    end
  end

  def owner_cannot_register
    return if user.blank? || event.blank?
    if event.club.is_owner?(user)
      errors.add(:base, "Event organizer is automatically a participant")
    end
  end
end
