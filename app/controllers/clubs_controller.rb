require "ostruct"

class ClubsController < ApplicationController
  before_action :authenticate_user!, except: %i[ index show ]
  before_action :set_club, only: %i[ edit update destroy ]

  # GET /clubs or /clubs.json
  def index
    # Temporary: display a catalog of ~100 fake clubs for styling and discovery
    # This does NOT hit the DB; it builds in-memory objects with Club-like attributes
    categories = %w[Running Cycling Swimming Football Basketball Tennis Volleyball Hiking Climbing Rowing]
    levels     = [ "Beginner", "Intermediate", "Advanced", "Expert" ]

    seed = 123
    srand(seed)

    @clubs = (1..100).map do |i|
      name = [
        "#{%w[North South East West Central Urban Rural Coastal Mountain Lakeside].sample} #{%w[Striders Cyclists Swimmers Runners Paddlers Racers Sprinters Wanderers Climbers Rowers].sample}",
        "#{%w[City County Metro Valley River Ridge Bay Prairie Forest Desert].sample} #{%w[Club Team Crew Squad League Collective Association Group Network].sample}"
      ].sample + " #{i}"

      category = categories.sample
      level    = levels.sample

      description = "A welcoming #{category.downcase} club for #{level.downcase} athletes. We meet weekly for training and events around the city."
      rules = "Be respectful, arrive on time, and support your teammates. Safety first on all outings."
      slug = name.parameterize

      OpenStruct.new(
        name: name,
        category: category,
        level: level,
        description: description,
        rules: rules,
        slug: slug
      )
    end

    # Simple search (by name, category, level, description)
    if params[:q].present?
      q = params[:q].to_s.downcase
      @clubs.select! do |c|
        [ c.name, c.category, c.level, c.description ].any? { |v| v.to_s.downcase.include?(q) }
      end
    end

    # Filter by exact category and level if provided
    if params[:category].present?
      @clubs.select! { |c| c.category == params[:category] }
    end

    if params[:level].present?
      @clubs.select! { |c| c.level == params[:level] }
    end
  end

  # GET /clubs/1 or /clubs/1.json
  def show
    # Temporary: build fake club data for display (no DB lookup)
    categories = %w[Running Cycling Swimming Football Basketball Tennis Volleyball Hiking Climbing Rowing]
    levels     = [ "Beginner", "Intermediate", "Advanced", "Expert" ]

    slug = params[:id].to_s
    # Derive a readable name from the slug
    name = slug.tr("-", " ").split.map(&:capitalize).join(" ")
    name = "Urban Striders" if name.blank?

    # Deterministic pick based on slug for stable display
    seed = slug.hash
    srand(seed)
    category = categories.sample
    level    = levels.sample

    # Deterministic members count (between 20 and 500)
    members_count = (seed.abs % 481) + 20

    # Longer description with interleaved images
    # Use deterministic Picsum seeds so refreshes are stable per club
    img1 = "https://picsum.photos/seed/#{slug}-1/1200/600"
    img2 = "https://picsum.photos/seed/#{slug}-2/1200/600"
    img3 = "https://picsum.photos/seed/#{slug}-3/1200/600"

    description = <<~HTML
      <p>Welcome to <strong>#{name}</strong>, a vibrant #{category.downcase} community for #{level.downcase} athletes and enthusiasts. We believe in building skills, friendships, and memories through weekly sessions, weekend adventures, and supportive coaching.</p>
      <p>Whether you're taking your first steps or chasing a new personal best, you'll find small group coaching, structured plans, and encouraging teammates. Our routes and workouts change with the season so there’s always something new to explore.</p>
      <img src="#{img1}" alt="#{name} photo 1" class="my-6 w-full rounded-lg object-cover shadow-sm" />
      <p>Typical meetups include technique drills, endurance efforts, and social cooldowns at local spots. We also organize periodic skills clinics led by experienced members and guest coaches, focusing on safety, form, and long-term progress.</p>
      <p>Community is at the heart of #{name}. New members are paired with buddies, and our chat stays active with route ideas, gear recommendations, and friendly challenges. Families and supporters are welcome at events and post-session hangouts.</p>
      <img src="#{img2}" alt="#{name} photo 2" class="my-6 w-full rounded-lg object-cover shadow-sm" />
      <p>We participate in charity events, fun runs, and inter-club scrimmages throughout the year. Our calendar includes accessible sessions for beginners as well as advanced training blocks for athletes preparing for competition.</p>
      <p>Ready to join? Come say hello at our next session and meet the crew. Your first visit is always free — just bring a smile and a willingness to try!</p>
      <img src="#{img3}" alt="#{name} photo 3" class="my-6 w-full rounded-lg object-cover shadow-sm" />
      <p>We look forward to training, learning, and celebrating together with you. See you soon!</p>
    HTML

    # Expanded rules list, similar length to description, bullet format and no images
    rules = <<~HTML
      <ul class="list-disc pl-6 space-y-2">
        <li>Respect everyone — all backgrounds, identities, and abilities are welcome.</li>
        <li>Safety first: follow leader instructions and local regulations at all times.</li>
        <li>Arrive on time and check in with a leader before we start.</li>
        <li>Use proper gear for the session and ensure equipment is in good condition.</li>
        <li>Communicate injuries, concerns, or route issues to leaders promptly.</li>
        <li>Keep shared routes and facilities clean; pack out what you bring in.</li>
        <li>Support a harassment-free environment; report issues immediately.</li>
        <li>During road/route use, obey traffic laws and yield to pedestrians.</li>
        <li>Headphones: allowed only when safe and when they do not impede awareness.</li>
        <li>Photography: ask consent before posting identifiable images of others.</li>
        <li>Be mindful of pace and regroup points; no one left behind on group days.</li>
        <li>Have fun, be kind, and help create a welcoming community.</li>
      </ul>
    HTML

    @club = OpenStruct.new(
      name: name,
      category: category,
      level: level,
      members_count: members_count,
      description: description,
      rules: rules,
      slug: slug
    )
  end

  # GET /clubs/new
  def new
    @club = current_user.clubs.new
  end

  # GET /clubs/1/edit
  def edit
  end

  # POST /clubs or /clubs.json
  def create
    @club = current_user.clubs.new(club_params)
    # Join multiple selected levels into a comma-separated string if provided as an array
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

  # PATCH/PUT /clubs/1 or /clubs/1.json
  def update
    # If multiple levels are submitted as array, convert to string before update
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

  # DELETE /clubs/1 or /clubs/1.json
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
  # Use callbacks to share common setup or constraints between actions.
  def set_club
    @club = Club.friendly.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def club_params
    params.require(:club).permit(:active, :name, :description, :category, :level, :rules, :public)
  end
end
