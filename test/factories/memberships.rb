# frozen_string_literal: true

# FactoryBot factories for Membership model
# Usage examples:
#   create(:membership)
#   create(:membership, :pending)
#   create(:membership, :disabled)

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
FactoryBot.define do
  factory :membership do
    association :user
    association :club
    status { "active" }
    role { "member" }

    trait :pending do
      status { "pending" }
    end

    trait :disabled do
      status { "disabled" }
    end
  end
end
