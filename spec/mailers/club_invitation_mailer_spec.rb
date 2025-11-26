require "rails_helper"

RSpec.describe ClubInvitationMailer, type: :mailer do
  describe "#invite" do
    let(:club) { create(:club) }
    let(:invited_by) { create(:user) }
    let(:invitation) { create(:club_invitation, club: club, invited_by: invited_by) }
    let(:mail) { described_class.invite(invitation) }

    it "has correct subject" do
      expect(mail.subject).to eq("You've been invited to join #{club.name}!")
    end

    it "sends to the invitation email" do
      expect(mail.to).to eq([ invitation.email ])
    end

    it "sends from the correct email" do
      expect(mail.from).to eq([ "no-reply@find-my.club" ])
    end

    it "includes greeting in body" do
      expect(mail.body.encoded).to match("Hi there")
    end

    it "includes club name in body" do
      expect(mail.body.encoded).to match(club.name)
    end

    it "includes inviter name in body" do
      expect(mail.body.encoded).to match(invited_by.first_name)
      expect(mail.body.encoded).to match(invited_by.last_name)
    end

    it "includes accept invitation link in body" do
      expect(mail.body.encoded).to match("invitations/#{invitation.token}/accept")
    end

    it "mentions 48 hours expiration" do
      expect(mail.body.encoded).to match("48 hours")
    end
  end
end
