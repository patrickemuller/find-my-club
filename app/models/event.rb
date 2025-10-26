# == Schema Information
#
# Table name: events
#
#  id               :bigint           not null, primary key
#  ends_at          :datetime         not null
#  has_waitlist     :boolean          default(FALSE), not null
#  location         :string           not null
#  location_name    :string           not null
#  max_participants :integer          default(10), not null
#  name             :string           not null
#  slug             :string
#  starts_at        :datetime         not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  club_id          :bigint           not null
#
# Indexes
#
#  index_events_on_club_id  (club_id)
#  index_events_on_slug     (slug) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (club_id => clubs.id)
#
class Event < ApplicationRecord
  extend FriendlyId

  friendly_id :name, use: :slugged

  belongs_to :club
  has_many :event_registrations, dependent: :destroy
  has_many :participants, through: :event_registrations, source: :user

  has_rich_text :description

  validates :name, :location, :location_name, :starts_at, :ends_at, presence: true
  validates :max_participants, presence: true, numericality: { greater_than_or_equal_to: 2 }
  validates :description, presence: true
  validate :ends_at_after_starts_at
  validate :starts_at_in_future, on: :create

  scope :upcoming, -> { where("starts_at > ?", Time.current).order(starts_at: :asc) }
  scope :past, -> { where("starts_at <= ?", Time.current).order(starts_at: :desc) }

  def in_progress?
    starts_at > Time.current
  end

  def should_generate_new_friendly_id?
    name_changed?
  end

  def full?
    confirmed_participants_count >= max_participants
  end

  def confirmed_participants_count
    event_registrations.confirmed.count
  end

  def waitlist_participants_count
    event_registrations.waitlist.count
  end

  def available_spots
    [ max_participants - confirmed_participants_count, 0 ].max
  end

  def user_registered?(user)
    return false unless user
    event_registrations.exists?(user_id: user.id)
  end

  def user_registration_status(user)
    return nil unless user
    event_registrations.find_by(user_id: user.id)&.status
  end

  private

  def ends_at_after_starts_at
    return if ends_at.blank? || starts_at.blank?
    errors.add(:ends_at, "must be after start date") if ends_at <= starts_at
  end

  def starts_at_in_future
    return if starts_at.blank?
    errors.add(:starts_at, "must be in the future") if starts_at <= Time.current
  end
end
