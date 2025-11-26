# frozen_string_literal: true

# FactoryBot factories for ClubInvitation model
# Usage examples:
#   create(:club_invitation)
#   create(:club_invitation, :accepted)
#   create(:club_invitation, :rejected)
#   create(:club_invitation, :expired)

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
FactoryBot.define do
  factory :club_invitation do
    association :club
    association :invited_by, factory: :user
    sequence(:email) { |n| "invited#{n}@example.com" }
    token { SecureRandom.urlsafe_base64(32) }
    expires_at { 48.hours.from_now }
    status { "pending" }

    trait :accepted do
      status { "accepted" }
      association :user
    end

    trait :rejected do
      status { "rejected" }
    end

    trait :expired do
      status { "expired" }
      expires_at { 1.hour.ago }
    end

    trait :expiring_soon do
      expires_at { 2.hours.from_now }
    end
  end
end
