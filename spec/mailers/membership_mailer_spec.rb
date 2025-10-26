require "rails_helper"

RSpec.describe MembershipMailer, type: :mailer do
  describe "#approved" do
    let(:membership) { create(:membership) }
    let(:mail) { described_class.approved(membership) }

    it "has correct subject" do
      expect(mail.subject).to eq("You've been approved to join #{membership.club.name}!")
    end

    it "sends to the user's email" do
      expect(mail.to).to eq([ membership.user.email ])
    end

    it "sends from the correct email" do
      expect(mail.from).to eq([ "from@example.com" ])
    end

    it "includes greeting in body" do
      expect(mail.body.encoded).to match("Hi")
    end
  end
end
