# frozen_string_literal: true

# FactoryBot factories for User model
# Usage examples:
#   create(:user)
#   build(:user)
#   create(:admin)

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
FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:first_name) { |n| "Alex #{n}" }
    sequence(:last_name) { |n| "Example #{n}" }
    password { "password" }
    password_confirmation { password }

    # Devise :confirmable — mark users confirmed by default for convenience in tests
    confirmed_at { Time.current }

    # Social media URLs - randomly assigned to ~60% of users
    strava_url { [ nil, nil, "https://www.strava.com/athletes/#{rand(1000000..9999999)}" ].sample }
    trailforks_url { [ nil, nil, "https://www.trailforks.com/profile/user#{rand(1000..9999)}/" ].sample }
    outside_url { [ nil, nil, "https://www.outsideinc.com/user#{rand(1000..9999)}" ].sample }
    athlinks_url { [ nil, nil, "https://www.athlinks.com/athletes/#{rand(100000..999999)}" ].sample }

    trait :unconfirmed do
      confirmed_at { nil }
    end

    trait :admin do
      admin { true }
    end

    trait :with_all_social_links do
      strava_url { "https://www.strava.com/athletes/#{rand(1000000..9999999)}" }
      trailforks_url { "https://www.trailforks.com/profile/user#{rand(1000..9999)}/" }
      outside_url { "https://www.outsideinc.com/user#{rand(1000..9999)}" }
      athlinks_url { "https://www.athlinks.com/athletes/#{rand(100000..999999)}" }
    end

    trait :without_social_links do
      strava_url { nil }
      trailforks_url { nil }
      outside_url { nil }
      athlinks_url { nil }
    end
  end
end
