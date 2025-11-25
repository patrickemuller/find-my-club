class ClubInvitationMailer < ApplicationMailer
  def invite(invitation)
    @invitation = invitation
    @club = invitation.club
    @invited_by = invitation.invited_by
    @accept_url = accept_club_invitation_url(token: invitation.token)

    mail(
      to: invitation.email,
      subject: "You've been invited to join #{@club.name}!"
    )
  end
end
