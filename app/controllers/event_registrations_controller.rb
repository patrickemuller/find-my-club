class EventRegistrationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_club_and_event
  before_action :authorize_owner!, only: [ :approve ]

  def create
    # Check if user is a member
    unless @club.has_member?(current_user)
      redirect_to club_event_path(@club, @event), alert: "Only club members can register for events"
      return
    end

    # Check if already registered
    if @event.user_registered?(current_user)
      redirect_to club_event_path(@club, @event), alert: "You are already registered for this event"
      return
    end

    # Determine status based on availability and waitlist settings
    status =
      if @event.full?
        if @event.has_waitlist?
          "waitlist"
        else
          redirect_to club_event_path(@club, @event), alert: "This event is full"
          return
        end
      else
        "confirmed"
      end

    registration = @event.event_registrations.new(user: current_user, status: status)

    if registration.save
      message = status == "confirmed" ? "You have successfully registered for this event!" : "You have been added to the waitlist."
      redirect_to club_event_path(@club, @event), notice: message
    else
      redirect_to club_event_path(@club, @event), alert: registration.errors.full_messages.join(", ")
    end
  end

  def destroy
    registration =
      if @club.is_owner?(current_user)
        # Owner can remove any registration
        @event.event_registrations.find(params[:id])
      else
        # Users can only remove their own registration
        @event.event_registrations.find_by(id: params[:id], user_id: current_user.id)
      end

    unless registration
      redirect_to club_event_path(@club, @event), alert: "Registration not found"
      return
    end

    user_name = registration.user.first_name
    registration.destroy!

    if @club.is_owner?(current_user)
      message = "#{user_name} has been removed from the event."
      redirect_path = registrations_club_event_path(@club, @event)
    else
      message = "You have cancelled your registration."
      redirect_path = club_event_path(@club, @event)
    end

    redirect_to redirect_path, notice: message, status: :see_other
  end

  def approve
    registration = @event.event_registrations.find(params[:id])

    # Can approve even if event is full (owner decision)
    if registration.update(status: "confirmed")
      redirect_to registrations_club_event_path(@club, @event), notice: "#{registration.user.first_name} has been approved and moved from waitlist to confirmed."
    else
      redirect_to registrations_club_event_path(@club, @event), alert: "Failed to approve registration"
    end
  end

  private

  def set_club_and_event
    @club = Club.friendly.find(params[:club_id])
    @event = @club.events.friendly.find(params[:event_id])
  end

  def authorize_owner!
    unless @club.is_owner?(current_user)
      redirect_to club_event_path(@club, @event), alert: "Only the event organizer can perform this action"
    end
  end
end
