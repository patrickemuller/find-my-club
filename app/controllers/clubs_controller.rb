require "ostruct"

class ClubsController < ApplicationController
  before_action :set_club, except: %i[index new create show my_clubs]
  before_action :authenticate_user!, except: %i[index show]
  before_action :authorize_club_owner!, only: %i[edit update destroy members enable disable]
  before_action :parse_category_and_level, only: %i[create update]
  before_action :ensure_club_setup_complete!, only: %i[members]

  rescue_from ActiveRecord::RecordNotFound do
    render file: "#{Rails.root}/public/404.html", layout: false, status: :not_found
  end

  def index
    @clubs = Club.publicly_visible
                 .complete_setup
                 .search(params[:q])
                 .with_category(params[:category])
                 .with_level(params[:level])
                 .page(params[:page])
  end

  def show
    # Do not raise an error here
    @club = Club.friendly.find(params[:id])

    # Disabled clubs should return 404
    if @club.disabled?
      render file: "#{Rails.root}/public/404.html", layout: false, status: :not_found
      return
    end

    # Paid clubs with incomplete setup should only be accessible to the owner
    if @club.incomplete_setup? && (!current_user || !@club.is_owner?(current_user))
      render file: "#{Rails.root}/public/404.html", layout: false, status: :not_found
      return
    end

    # Load upcoming events for members and owners (limit to 3 for preview)
    if current_user && (@club.has_member?(current_user) || @club.is_owner?(current_user))
      @upcoming_events = @club.events.upcoming.limit(6)
    end
  end

  def new
    @club = current_user.clubs.new
  end

  def edit
    @club = current_user.clubs.friendly.find(params[:id])
  end

  def create
    @club = current_user.clubs.new(club_params)

    respond_to do |format|
      if @club.save
        # Redirect to Stripe setup if this is a paid club
        if @club.paid?
          format.html { redirect_to club_payments_path(@club), notice: "Club created! Now let's set up payments." }
          format.json { render :show, status: :created, location: @club }
        else
          format.html { redirect_to @club, notice: "Club was successfully created." }
          format.json { render :show, status: :created, location: @club }
        end
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @club.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    @club = current_user.clubs.friendly.find(params[:id])
    was_paid = @club.paid?

    respond_to do |format|
      if @club.update(club_params)
        # If club was just changed to paid, redirect to Stripe setup
        if @club.paid? && !was_paid
          format.html { redirect_to club_payments_path(@club), notice: "Club updated! Now let's set up payments." }
          format.json { render :show, status: :ok, location: @club }
        else
          format.html { redirect_to @club, notice: "Club was successfully updated.", status: :see_other }
          format.json { render :show, status: :ok, location: @club }
        end
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @club.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @club = current_user.clubs.friendly.find(params[:id])

    @club.destroy!

    respond_to do |format|
      format.html { redirect_to my_clubs_path, notice: "Club was successfully deleted.", status: :see_other }
      format.json { head :no_content }
    end
  end

  def my_clubs
    @clubs = current_user.clubs
    @memberships = current_user.clubs_as_member.where(memberships: { status: %w[active pending] }).includes(:owner)
    @pending_invitations = ClubInvitation.pending.for_email(current_user.email).includes(:club, :invited_by)
  end

  def members
    @club = current_user.clubs.friendly.find(params[:id])
    @active_members = @club.memberships.active.includes(:user)
    @pending_members = @club.memberships.pending.includes(:user)
    @disabled_members = @club.memberships.disabled.includes(:user)
    @pending_invitations = @club.club_invitations.pending.includes(:invited_by)
  end

  def enable
    @club = current_user.clubs.friendly.find(params[:id])
    @club.update(active: true)

    respond_to do |format|
      format.html { redirect_to my_clubs_path, notice: "Club was successfully enabled.", status: :see_other }
      format.json { render :show, status: :ok, location: @club }
    end
  end

  def disable
    @club = current_user.clubs.friendly.find(params[:id])
    @club.update(active: false)

    respond_to do |format|
      format.html { redirect_to my_clubs_path, notice: "Club was successfully disabled.", status: :see_other }
      format.json { render :show, status: :ok, location: @club }
    end
  end

  private

  def parse_category_and_level
    # Instead of using an array, save on a single string for now
    # TODO: Refactor this to use an array
    if params[:club] && params[:club][:category].is_a?(Array)
      params[:club][:category] = params[:club][:category].reject(&:blank?).join(", ")
    end

    if params[:club] && params[:club][:level].is_a?(Array)
      params[:club][:level] = params[:club][:level].reject(&:blank?).join(", ")
    end
  end

  def set_club
    @club = Club.friendly.find(params[:id])
  end

  def club_params
    params.require(:club).permit(:active, :name, :description, :rules, :public, :category, :level, :paid)
  end

  def authorize_club_owner!
    current_user == @club.owner
  end

  def ensure_club_setup_complete!
    if @club.incomplete_setup?
      redirect_to club_payments_path(@club), alert: "Please complete your Stripe setup first"
    end
  end
end
