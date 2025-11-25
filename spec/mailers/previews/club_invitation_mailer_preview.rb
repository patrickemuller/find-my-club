# Preview all emails at http://localhost:3000/rails/mailers/club_invitation_mailer
class ClubInvitationMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/club_invitation_mailer/invite
  def invite
    # Create sample data for preview
    invited_by = User.new(
      email: "owner@example.com",
      first_name: "Sarah",
      last_name: "Johnson"
    )

    club = Club.new(
      name: "Mountain Biking Enthusiasts",
      slug: "mountain-biking-enthusiasts",
      category: "cycling_sports",
      level: "intermediate"
    )

    invitation = ClubInvitation.new(
      email: "newmember@example.com",
      club: club,
      invited_by: invited_by,
      token: SecureRandom.urlsafe_base64(32),
      expires_at: 48.hours.from_now,
      status: "pending"
    )

    ClubInvitationMailer.invite(invitation)
  end
end
