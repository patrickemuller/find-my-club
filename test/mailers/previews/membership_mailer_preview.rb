# Preview all emails at http://localhost:3000/rails/mailers/membership_mailer
class MembershipMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/membership_mailer/approved
  def approved
    # Create sample data for preview
    user = User.new(
      email: "member@example.com",
      first_name: "John",
      last_name: "Doe"
    )

    club = Club.new(
      name: "Downtown Runners Club",
      slug: "downtown-runners-club"
    )

    membership = Membership.new(
      user: user,
      club: club,
      status: "active",
      role: "member"
    )

    MembershipMailer.approved(membership)
  end
end
