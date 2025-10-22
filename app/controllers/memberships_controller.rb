class MembershipsController < ApplicationController
  before_action :set_club
  before_action :authenticate_user!
  before_action :set_membership, only: [ :approve, :enable, :disable ]
  before_action :authorize_owner!, only: [ :approve, :enable, :disable ]

  def create
    # Check if user can join
    unless current_user.can_join?(@club)
      redirect_to @club, alert: "You cannot join this club." and return
    end

    # Public clubs: auto-approve, Private clubs: pending approval
    membership_status = @club.public? ? "active" : "pending"

    @membership = @club.memberships.new(
      user: current_user,
      status: membership_status,
      role: "member"
    )

    if @membership.save
      if @club.public?
        redirect_to @club, notice: "You have successfully joined #{@club.name}!"
      else
        redirect_to @club, notice: "Your request to join #{@club.name} is pending approval from the club owner."
      end
    else
      redirect_to @club, alert: "Unable to join club: #{@membership.errors.full_messages.join(', ')}"
    end
  end

  def destroy
    # Check if owner is removing a member or user is leaving
    if @club.is_owner?(current_user) && params[:membership_id]
      @membership = @club.memberships.find(params[:membership_id])
      @membership.destroy
      redirect_to members_club_path(@club), notice: "Member has been removed from the club."
    else
      # User leaving club
      @membership = current_user.memberships.find_by(club_id: @club.id)

      if @membership.blank?
        redirect_to @club, alert: "You are not a member of this club." and return
      end

      @membership.destroy
      redirect_to @club, notice: "You have left #{@club.name}."
    end
  end

  def approve
    if @membership.update(status: "active")
      MembershipMailer.approved(@membership).deliver_later
      redirect_to members_club_path(@club), notice: "#{@membership.user.first_name} has been approved and is now an active member."
    else
      redirect_to members_club_path(@club), alert: "Unable to approve member."
    end
  end

  def enable
    if @membership.update(status: "active")
      redirect_to members_club_path(@club), notice: "#{@membership.user.first_name} has been enabled."
    else
      redirect_to members_club_path(@club), alert: "Unable to enable member."
    end
  end

  def disable
    if @membership.update(status: "disabled")
      redirect_to members_club_path(@club), notice: "#{@membership.user.first_name} has been disabled."
    else
      redirect_to members_club_path(@club), alert: "Unable to disable member."
    end
  end

  private

  def set_club
    @club = Club.friendly.find(params[:club_id])
  end

  def set_membership
    @membership = @club.memberships.find(params[:id])
  end

  def authorize_owner!
    unless @club.is_owner?(current_user)
      redirect_to @club, alert: "You are not authorized to perform this action." and return
    end
  end
end
