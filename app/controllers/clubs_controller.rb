require "ostruct"

class ClubsController < ApplicationController
  before_action :authenticate_user!, except: %i[index show]
  before_action :set_club, only: %i[show]
  before_action :parse_category_and_level, only: %i[create update]

  def index
    @clubs = Club.publicly_visible
                 .search(params[:q])
                 .with_category(params[:category])
                 .with_level(params[:level])
                 .page(params[:page])
  end

  def show
    # Do not raise an error here
    @club = Club.friendly.find(params[:id])

    # Private clubs should not be accessible using URL guessing
    # If you are the owner, you can access it
    if @club.blank? || (!current_user && !@club.is_owner?(current_user)) || (@club.disabled? || !@club.public?)
      render file: "#{Rails.root}/public/404.html", layout: false, status: :not_found
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
        format.html { redirect_to @club, notice: "Club was successfully created." }
        format.json { render :show, status: :created, location: @club }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @club.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    @club = current_user.clubs.friendly.find(params[:id])

    respond_to do |format|
      if @club.update(club_params)
        format.html { redirect_to @club, notice: "Club was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @club }
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
      format.html { redirect_to my_clubs_path, notice: "Club was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  def my_clubs
    @clubs = current_user.clubs
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
    params.require(:club).permit(:active, :name, :description, :rules, :public, :category, :level)
  end
end
