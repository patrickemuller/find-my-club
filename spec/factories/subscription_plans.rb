# == Schema Information
#
# Table name: subscription_plans
#
#  id                :bigint           not null, primary key
#  active            :boolean          default(TRUE), not null
#  currency          :string           default("cad"), not null
#  description       :text
#  name              :string
#  plan_type         :string           not null
#  price_cents       :integer          not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  club_id           :bigint           not null
#  stripe_product_id :string           not null
#
# Indexes
#
#  index_subscription_plans_on_club_id            (club_id)
#  index_subscription_plans_on_stripe_product_id  (stripe_product_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (club_id => clubs.id)
#
FactoryBot.define do
  factory :subscription_plan do
    association :club
    name { "Standard Plan" }
    stripe_product_id { "price_#{SecureRandom.hex(12)}" }
    plan_type { "month" }
    price_cents { 2000 }
    currency { "cad" }
    description { "A standard monthly subscription plan" }
    active { true }

    trait :weekly do
      plan_type { "week" }
      price_cents { 500 }
      description { "A weekly subscription plan" }
    end

    trait :yearly do
      plan_type { "year" }
      price_cents { 20000 }
      description { "An annual subscription plan" }
    end

    trait :inactive do
      active { false }
    end
  end
end
