class CreateInvoices < ActiveRecord::Migration[8.1]
  def change
    create_table :invoices do |t|
      t.references :user, null: false, foreign_key: true
      t.string :stripe_invoice_id, null: false
      t.string :stripe_subscription_id
      t.string :club_name, null: false
      t.integer :amount_cents, null: false
      t.string :currency, null: false
      t.string :status, null: false
      t.string :invoice_number
      t.string :invoice_pdf_url
      t.datetime :period_start
      t.datetime :period_end
      t.datetime :paid_at

      t.timestamps
    end

    add_index :invoices, :stripe_invoice_id, unique: true
  end
end
