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
FactoryBot.define do
  factory :event do
    association :club
    sequence(:name) { |n| "Training Session #{n}" }
    description { "Join us for an awesome training session!" }
    location { "https://maps.google.com/?q=Gym+Downtown" }
    location_name { "Gym Downtown" }
    starts_at { 1.day.from_now }
    ends_at { 1.day.from_now + 2.hours }
    max_participants { 10 }
    has_waitlist { false }

    trait :with_waitlist do
      has_waitlist { true }
    end

    trait :full do
      after(:create) do |event|
        create_list(:event_registration, event.max_participants, event: event)
      end
    end

    trait :past do
      starts_at { 1.week.ago }
      ends_at { 1.week.ago + 2.hours }
    end
  end
end
