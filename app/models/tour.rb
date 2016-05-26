class Tour < ActiveRecord::Base
  belongs_to :user

  has_many :waypoints

  validates :name, presence: true

  accepts_nested_attributes_for :waypoints

  before_save :set_directions

  def as_json(options = {})
    full = options.delete(:full) == true
    user = {
      except: :token,
      methods: :picture_url
    }

    waypoints = {
      methods: :image_url
    }

    options.merge! include: { waypoints: waypoints, user: user }, methods: [:polyline, :duration]

    if !full
      options.merge! except: :directions
    end

    super(options)
  end

  def polyline
    directions["routes"][0]["overview_polyline"]["points"] rescue nil
  end

  def duration
    total_seconds = 0

    directions["routes"][0]["legs"].each do |leg|
      leg["steps"].each do |step|
        total_seconds += step["duration"]["value"]
      end
    end

    ActionController::Base.helpers.distance_of_time_in_words(total_seconds.seconds)
  end

  def set_directions
    url = "https://maps.googleapis.com/maps/api/directions/json?key=#{Figaro.env.google_maps_key}"
    waypoint_coordinates = waypoints.map { |waypoint| waypoint.coordinates_string }

    url << "&origin=#{waypoint_coordinates.shift}"
    url << "&destination=#{waypoint_coordinates.pop}"

    if waypoint_coordinates.count > 0
      url << "&waypoints=#{waypoint_coordinates.join("|")}"
    end

    self.directions = RestClient.get(url)
  end
end