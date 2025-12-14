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
#  country_code           :string
#  current_sign_in_at     :datetime
#  current_sign_in_ip     :string
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  first_name             :string           not null
#  last_name              :string           not null
#  last_sign_in_at        :datetime
#  last_sign_in_ip        :string
#  outside_url            :string
#  phone_number           :string
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
class User < ApplicationRecord
  include ActionView::Helpers::NumberHelper

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :trackable

  validates :first_name, :last_name, presence: true
  validates :phone_number, :country_code, presence: true

  # Avatar attachment
  has_one_attached :avatar
  validate :validate_avatar

  # Phone number validation
  validate :validate_phone_number_format

  # Social media URL validations
  validates :strava_url,
            format: { with: %r{\Ahttps://www\.strava\.com/(athletes|pros)/.+\z}, message: "must be a valid Strava profile URL (https://www.strava.com/athletes/... or /pros/...)" },
            allow_blank: true

  validates :trailforks_url,
            format: { with: %r{\Ahttps://www\.trailforks\.com/profile/.+\z}, message: "must be a valid TrailForks profile URL (https://www.trailforks.com/profile/...)" },
            allow_blank: true

  validates :outside_url,
            format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "must be a valid URL" },
            allow_blank: true

  validates :athlinks_url,
            format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "must be a valid URL" },
            allow_blank: true

  validate :validate_social_media_urls

  # Ownership
  has_many :clubs, class_name: "Club", foreign_key: :owner_id, dependent: :destroy

  # Membership
  has_many :memberships, dependent: :destroy
  has_many :clubs_as_member, through: :memberships, source: :club

  # Invitations
  has_many :received_invitations, class_name: "ClubInvitation", foreign_key: :user_id
  has_many :pending_club_invitations, -> { pending }, class_name: "ClubInvitation", primary_key: :email, foreign_key: :email

  # Invoices
  has_many :invoices, dependent: :destroy

  # Helper methods
  def member_of?(club)
    memberships.active.exists?(club_id: club.id)
  end

  def can_join?(club)
    return false if club.owner == self  # Owner can't join their own club
    return false if memberships.exists?(club_id: club.id, status: %w[active pending])  # Already has a membership (either active or pending)
    true
  end

  # Extract username from social media URLs
  def strava_username
    return nil unless strava_url.present?
    strava_url.match(%r{/(athletes|pros)/(.+?)(?:/|$)})&.[](2)
  end

  def trailforks_username
    return nil unless trailforks_url.present?
    username = trailforks_url.match(%r{/profile/(.+?)(?:/|$)})&.[](1)
    username&.gsub(/\/$/, "") # Remove trailing slash if present
  end

  def outside_username
    return nil unless outside_url.present?
    # Extract the last path segment as username
    uri = URI.parse(outside_url)
    username = uri.path.split("/").reject(&:empty?).last
    username
  rescue URI::InvalidURIError
    nil
  end

  def athlinks_username
    return nil unless athlinks_url.present?
    athlinks_url.match(%r{/athletes/(.+?)(?:/|$)})&.[](1)
  end

  def formatted_phone_number
    return nil unless phone_number.present? && country_code.present?
    parsed = Phonelib.parse(phone_number, country_code)
    parsed.valid? ? parsed.international : phone_number
  end

  private

  def validate_avatar
    return unless avatar.attached?

    # Validate content type
    unless avatar.content_type.in?(%w[image/jpeg image/png image/gif image/webp])
      errors.add(:avatar, "must be an image file")
    end

    # Validate file size
    if avatar.byte_size > 10.megabytes
      current_size = number_to_human_size(avatar.byte_size)
      errors.add(:avatar, "file size must be less than 10 MB, your file is #{current_size}")
    end
  end

  def validate_phone_number_format
    return if phone_number.blank? || country_code.blank?

    parsed = Phonelib.parse(phone_number, country_code)
    unless parsed.valid?
      errors.add(:phone_number, "is invalid for selected country")
    end
  end

  def validate_social_media_urls
    validate_parsed_url(:strava_url, "www.strava.com")
    validate_parsed_url(:trailforks_url, "www.trailforks.com")
    validate_parsed_url(:outside_url, nil)
    validate_parsed_url(:athlinks_url, nil)
  end

  def validate_parsed_url(attribute, expected_host = nil)
    url_value = send(attribute)
    return if url_value.blank?

    begin
      uri = URI.parse(url_value)

      # Ensure it's a valid HTTP/HTTPS URL
      unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
        errors.add(attribute, "must be a valid HTTP or HTTPS URL")
        return
      end

      # Check for expected host if specified
      if expected_host && uri.host != expected_host
        errors.add(attribute, "must be from #{expected_host}")
        return
      end

      # Ensure the URL doesn't contain potentially malicious content
      if url_value.match?(/[<>\"']|javascript:|data:|vbscript:|<script|on\w+=/i)
        errors.add(attribute, "contains invalid characters")
      end
    rescue URI::InvalidURIError
      errors.add(attribute, "is not a valid URL")
    end
  end
end
