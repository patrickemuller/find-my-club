class EventsController < ApplicationController
  before_action :authenticate_user!, except: [ :show, :index ]
  before_action :set_club
  before_action :set_event, only: [ :show, :edit, :update, :destroy, :registrations ]
  before_action :authorize_owner!, only: [ :new, :create, :edit, :update, :destroy, :registrations ]

  def index
    @upcoming_events = @club.events.upcoming
    @past_events = @club.events.past
    @events_json = @club.events.order(starts_at: :asc).map do |event|
      {
        id: event.id,
        name: event.name,
        starts_at: event.starts_at.iso8601,
        url: club_event_path(@club, event)
      }
    end.to_json
  end

  def show
    # Accessible to club members and owner
    unless current_user && (@club.has_member?(current_user) || @club.is_owner?(current_user))
      redirect_to club_path(@club), alert: "Only club members can view events"
      return
    end

    @confirmed_registrations = @event.event_registrations.confirmed.includes(:user)
    @waitlist_registrations = @event.event_registrations.waitlist.includes(:user)
  end

  def new
    @event = @club.events.new(starts_at: Time.current, ends_at: Time.current + 2.hours)
  end

  def create
    @event = @club.events.new(event_params)

    if @event.save
      redirect_to club_event_path(@club, @event), notice: "Event was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @event.update(event_params)
      redirect_to club_event_path(@club, @event), notice: "Event was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @event.destroy!
    redirect_to club_events_path(@club), notice: "Event was successfully deleted.", status: :see_other
  end

  def registrations
    @confirmed_registrations = @event.event_registrations.confirmed.includes(:user)
    @waitlist_registrations = @event.event_registrations.waitlist.includes(:user)
  end

  private

  def set_club
    @club = Club.friendly.find(params[:club_id])
  end

  def set_event
    @event = @club.events.friendly.find(params[:id])
  end

  def authorize_owner!
    unless @club.is_owner?(current_user)
      redirect_to club_path(@club), alert: "Only the club owner can manage events"
    end
  end

  def event_params
    params.require(:event).permit(:name, :description, :location, :location_name, :starts_at, :ends_at, :max_participants, :has_waitlist)
  end
end
