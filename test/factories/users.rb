# frozen_string_literal: true

# FactoryBot factories for User model
# Usage examples:
#   create(:user)
#   build(:user)
#   create(:admin)

FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:first_name) { |n| "Alex #{n}" }
    sequence(:last_name) { |n| "Example #{n}" }
    password { "password" }
    password_confirmation { password }

    # Devise :confirmable — mark users confirmed by default for convenience in tests
    confirmed_at { Time.current }

    trait :unconfirmed do
      confirmed_at { nil }
    end

    trait :admin do
      admin { true }
    end
  end
end
