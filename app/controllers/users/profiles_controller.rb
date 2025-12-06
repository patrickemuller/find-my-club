class Users::ProfilesController < ApplicationController
  before_action :set_user

  def show
    @clubs = @user.clubs_as_member.where(public: true)
    @owned_clubs = @user.clubs.where(public: true)
    @all_user_clubs = (@clubs + @owned_clubs).uniq

    # Get recent past events the user participated in (anonymously - just event and club name)
    @recent_events = Event.joins(event_registrations: :user)
                          .where(event_registrations: { user_id: @user.id, status: "confirmed" })
                          .where("events.starts_at < ?", Time.current)
                          .order(starts_at: :desc)
                          .limit(5)
                          .includes(:club)
  end

  private

  def set_user
    @user = User.find(params[:id])
  end
end
