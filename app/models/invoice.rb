# == Schema Information
#
# Table name: invoices
#
#  id                     :bigint           not null, primary key
#  amount_cents           :integer          not null
#  club_name              :string           not null
#  currency               :string           not null
#  invoice_number         :string
#  invoice_pdf_url        :string
#  paid_at                :datetime
#  period_end             :datetime
#  period_start           :datetime
#  status                 :string           not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  stripe_invoice_id      :string           not null
#  stripe_subscription_id :string
#  user_id                :bigint           not null
#
# Indexes
#
#  index_invoices_on_stripe_invoice_id  (stripe_invoice_id) UNIQUE
#  index_invoices_on_user_id            (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class Invoice < ApplicationRecord
  belongs_to :user

  validates :stripe_invoice_id, presence: true, uniqueness: true
  validates :club_name, :amount_cents, :currency, :status, presence: true

  def amount_in_dollars
    amount_cents / 100.0
  end
end
