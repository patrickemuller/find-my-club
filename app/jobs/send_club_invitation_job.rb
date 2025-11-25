class SendClubInvitationJob < ApplicationJob
  queue_as :default

  def perform(invitation_id)
    invitation = ClubInvitation.find(invitation_id)
    return unless invitation.pending?

    ClubInvitationMailer.invite(invitation).deliver_now
  end
end
