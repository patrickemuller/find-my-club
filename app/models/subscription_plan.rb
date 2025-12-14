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
class SubscriptionPlan < ApplicationRecord
  attribute :currency, :string, default: "cad"

  belongs_to :club

  PLAN_TYPES = %w[week month year].freeze

  validates :plan_type, presence: true, inclusion: { in: PLAN_TYPES }
  validates :price_cents, presence: true, numericality: { greater_than: 0 }
  validates :name, :description, :currency, presence: true
  validates :description, length: { maximum: 250 }
  validates :stripe_product_id, presence: true, uniqueness: true

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :weekly, -> { where(plan_type: "week") }
  scope :monthly, -> { where(plan_type: "month") }
  scope :yearly, -> { where(plan_type: "year") }

  def price_in_dollars
    price_cents / 100.0 rescue 0
  end

  def interval
    case plan_type
    when "week" then "weekly"
    when "month" then "monthly"
    when "year" then "annual"
    end
  end
end
