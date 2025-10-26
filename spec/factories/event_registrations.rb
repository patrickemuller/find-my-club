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
FactoryBot.define do
  factory :event_registration do
    association :event
    association :user
    status { "confirmed" }

    trait :waitlist do
      status { "waitlist" }
    end
  end
end
