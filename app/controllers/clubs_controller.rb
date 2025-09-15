require "ostruct"

class ClubsController < ApplicationController
  before_action :authenticate_user!, except: %i[index show]
  before_action :set_club, only: %i[edit update destroy]

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
    if @club.blank? || !@club.active? || !@club.public?
      render file: "#{Rails.root}/public/404.html", layout: false, status: :not_found
    end
  end

  def new
    @club = current_user.clubs.new
  end

  def edit; end

  def create
    @club = current_user.clubs.new(club_params)
    if params[:club] && params[:club][:level].is_a?(Array)
      @club.level = params[:club][:level].reject(&:blank?).join(", ")
    end

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
    levels_param = params.dig(:club, :level)
    if levels_param.is_a?(Array)
      params[:club][:level] = levels_param.reject(&:blank?).join(", ")
    end

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
    @club.destroy!

    respond_to do |format|
      format.html { redirect_to clubs_path, notice: "Club was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  def my_clubs
    @clubs = current_user.clubs
  end

  private

  def set_club
    @club = Club.friendly.find(params[:id])
  end

  def club_params
    params.require(:club).permit(:active, :name, :description, :category, :level, :rules, :public)
  end
end
