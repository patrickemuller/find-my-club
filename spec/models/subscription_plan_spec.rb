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
require "rails_helper"

RSpec.describe SubscriptionPlan, type: :model do
  let(:club) { create(:club) }
  let(:subscription_plan) { build(:subscription_plan, club: club) }

  describe "validations" do
    it "is valid with valid attributes" do
      expect(subscription_plan).to be_valid
    end

    it "requires plan_type" do
      subscription_plan.plan_type = nil
      expect(subscription_plan).not_to be_valid
      expect(subscription_plan.errors[:plan_type]).to include("can't be blank")
    end

    it "validates plan_type is in allowed values" do
      subscription_plan.plan_type = "invalid"
      expect(subscription_plan).not_to be_valid
      expect(subscription_plan.errors[:plan_type]).to include("is not included in the list")
    end

    it "allows valid plan_types" do
      %w[week month year].each do |type|
        subscription_plan.plan_type = type
        expect(subscription_plan).to be_valid
      end
    end

    it "requires price_cents" do
      subscription_plan.price_cents = nil
      expect(subscription_plan).not_to be_valid
      expect(subscription_plan.errors[:price_cents]).to include("can't be blank")
    end

    it "validates price_cents is greater than 0" do
      subscription_plan.price_cents = 0
      expect(subscription_plan).not_to be_valid
      expect(subscription_plan.errors[:price_cents]).to include("must be greater than 0")

      subscription_plan.price_cents = -100
      expect(subscription_plan).not_to be_valid
      expect(subscription_plan.errors[:price_cents]).to include("must be greater than 0")
    end

    it "requires name" do
      subscription_plan.name = nil
      expect(subscription_plan).not_to be_valid
      expect(subscription_plan.errors[:name]).to include("can't be blank")
    end

    it "requires description" do
      subscription_plan.description = nil
      expect(subscription_plan).not_to be_valid
      expect(subscription_plan.errors[:description]).to include("can't be blank")
    end

    it "validates description length" do
      subscription_plan.description = "a" * 251
      expect(subscription_plan).not_to be_valid
      expect(subscription_plan.errors[:description]).to include("is too long (maximum is 250 characters)")

      subscription_plan.description = "a" * 250
      expect(subscription_plan).to be_valid
    end

    it "requires currency" do
      subscription_plan.currency = nil
      expect(subscription_plan).not_to be_valid
      expect(subscription_plan.errors[:currency]).to include("can't be blank")
    end

    it "requires stripe_product_id" do
      subscription_plan.stripe_product_id = nil
      expect(subscription_plan).not_to be_valid
      expect(subscription_plan.errors[:stripe_product_id]).to include("can't be blank")
    end

    it "validates uniqueness of stripe_product_id" do
      subscription_plan.save!
      duplicate_plan = build(:subscription_plan, stripe_product_id: subscription_plan.stripe_product_id)
      expect(duplicate_plan).not_to be_valid
      expect(duplicate_plan.errors[:stripe_product_id]).to include("has already been taken")
    end
  end

  describe "associations" do
    it "belongs to club" do
      expect(subscription_plan.club).to eq(club)
    end

    it "requires club" do
      subscription_plan.club = nil
      expect(subscription_plan).not_to be_valid
    end
  end

  describe "scopes" do
    let!(:active_monthly) { create(:subscription_plan, active: true, plan_type: "month") }
    let!(:inactive_monthly) { create(:subscription_plan, :inactive, plan_type: "month") }
    let!(:active_weekly) { create(:subscription_plan, :weekly, active: true) }
    let!(:active_yearly) { create(:subscription_plan, :yearly, active: true) }

    describe ".active" do
      it "returns only active plans" do
        expect(SubscriptionPlan.active).to include(active_monthly, active_weekly, active_yearly)
        expect(SubscriptionPlan.active).not_to include(inactive_monthly)
      end
    end

    describe ".inactive" do
      it "returns only inactive plans" do
        expect(SubscriptionPlan.inactive).to include(inactive_monthly)
        expect(SubscriptionPlan.inactive).not_to include(active_monthly, active_weekly, active_yearly)
      end
    end

    describe ".weekly" do
      it "returns only weekly plans" do
        expect(SubscriptionPlan.weekly).to include(active_weekly)
        expect(SubscriptionPlan.weekly).not_to include(active_monthly, inactive_monthly, active_yearly)
      end
    end

    describe ".monthly" do
      it "returns only monthly plans" do
        expect(SubscriptionPlan.monthly).to include(active_monthly, inactive_monthly)
        expect(SubscriptionPlan.monthly).not_to include(active_weekly, active_yearly)
      end
    end

    describe ".yearly" do
      it "returns only yearly plans" do
        expect(SubscriptionPlan.yearly).to include(active_yearly)
        expect(SubscriptionPlan.yearly).not_to include(active_monthly, inactive_monthly, active_weekly)
      end
    end
  end

  describe "#price_in_dollars" do
    it "converts price_cents to dollars" do
      subscription_plan.price_cents = 2000
      expect(subscription_plan.price_in_dollars).to eq(20.0)
    end

    it "handles zero price" do
      subscription_plan.price_cents = 0
      expect(subscription_plan.price_in_dollars).to eq(0.0)
    end

    it "handles fractional dollars" do
      subscription_plan.price_cents = 1550
      expect(subscription_plan.price_in_dollars).to eq(15.5)
    end

    it "returns 0 on error" do
      subscription_plan.price_cents = nil
      expect(subscription_plan.price_in_dollars).to eq(0)
    end
  end

  describe "#interval" do
    it "returns 'weekly' for week plan_type" do
      subscription_plan.plan_type = "week"
      expect(subscription_plan.interval).to eq("weekly")
    end

    it "returns 'monthly' for month plan_type" do
      subscription_plan.plan_type = "month"
      expect(subscription_plan.interval).to eq("monthly")
    end

    it "returns 'annual' for year plan_type" do
      subscription_plan.plan_type = "year"
      expect(subscription_plan.interval).to eq("annual")
    end

    it "returns nil for invalid plan_type" do
      subscription_plan.plan_type = "invalid"
      expect(subscription_plan.interval).to be_nil
    end
  end

  describe "default values" do
    it "defaults currency to 'cad'" do
      plan = SubscriptionPlan.new
      expect(plan.currency).to eq("cad")
    end

    it "defaults active to true" do
      plan = create(:subscription_plan)
      expect(plan.active).to be true
    end
  end
end
