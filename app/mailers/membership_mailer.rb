class MembershipMailer < ApplicationMailer
  def approved(membership)
    @membership = membership
    @user = membership.user
    @club = membership.club

    mail(
      to: @user.email,
      subject: "You've been approved to join #{@club.name}!"
    )
  end
end
