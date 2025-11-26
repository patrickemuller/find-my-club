class ClubInvitationsController < ApplicationController
  before_action :authenticate_user!, except: [ :accept, :reject ]
  before_action :set_club, only: [ :new, :create ]
  before_action :authorize_owner!, only: [ :new, :create ]
  before_action :set_invitation_by_token, only: [ :accept, :reject ]

  rescue_from ActiveRecord::RecordNotFound do
    redirect_to root_path, alert: "Invitation not found."
  end

  def new
    # Modal form, no need for a view
  end

  def create
    emails = parse_emails(params[:emails])

    @results = { success: [], errors: [] }

    emails.each do |email|
      invitation = @club.club_invitations.new(
        email: email,
        invited_by: current_user
      )

      if invitation.save
        SendClubInvitationJob.perform_later(invitation.id)
        @results[:success] << email
      else
        @results[:errors] << { email: email, error: invitation.errors.full_messages.join(", ") }
      end
    end

    if @results[:errors].empty?
      redirect_to members_club_path(@club), notice: "Invitations sent successfully to #{@results[:success].size} #{'email'.pluralize(@results[:success].size)}."
    else
      flash.now[:alert] = "Some invitations failed: #{@results[:errors].map { |e| "#{e[:email]} (#{e[:error]})" }.join(", ")}"
      redirect_to members_club_path(@club), alert: flash[:alert]
    end
  end

  def accept
    unless user_signed_in?
      # Store token in session and redirect to sign up/login
      session[:pending_invitation_token] = @invitation.token
      redirect_to new_user_registration_path, notice: "Please sign up or log in to accept this invitation."
      return
    end

    # Validate that logged-in user's email matches the invitation email
    unless current_user.email.downcase == @invitation.email.downcase
      redirect_to my_clubs_path, alert: "There was an error accepting the invitation."
      return
    end

    if @invitation.accept!(current_user)
      redirect_to club_path(@invitation.club), notice: "You've successfully joined #{@invitation.club.name}!"
    else
      redirect_to my_clubs_path, alert: "Unable to accept invitation. It may have expired or already been used."
    end
  end

  def reject
    unless user_signed_in?
      redirect_to root_path, alert: "You must be logged in to reject an invitation."
      return
    end

    if @invitation.reject!
      redirect_to my_clubs_path, notice: "Invitation rejected."
    else
      redirect_to my_clubs_path, alert: "Unable to reject invitation."
    end
  end

  private

  def set_club
    @club = current_user.clubs.friendly.find(params[:club_id])
  end

  def authorize_owner!
    unless @club.is_owner?(current_user)
      redirect_to club_path(@club), alert: "You must be the club owner to invite members."
    end
  end

  def set_invitation_by_token
    @invitation = ClubInvitation.find_by!(token: params[:token])
  end

  def parse_emails(emails_string)
    emails_string.to_s.split(/[\n,;]/).map(&:strip).reject(&:blank?).uniq
  end
end
