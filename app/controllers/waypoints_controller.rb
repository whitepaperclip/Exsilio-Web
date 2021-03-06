class WaypointsController < ApiController
  before_action :authenticate_user!
  before_action :set_tour

  def create
    waypoint = @tour.waypoints.new(waypoint_params)
    waypoint.position = (@tour.waypoints.map(&:position).select(&:present?).max || 0) + 1

    if waypoint.save
      render json: waypoint
    else
      render json: { errors: waypiont.errors.full_messages.join(". ") }
    end
  end

  def update
    waypoint = @tour.waypoints.find(params[:id])

    if waypoint.update_attributes(waypoint_params)
      render json: waypoint
    else
      render json: { errors: waypoint.errors.full_messages.join(". ") }
    end
  end

  def reposition
    @tour.reposition_waypoints!(params["waypoints"])

    head :ok
  end

  def destroy
    waypoint = @tour.waypoints.find(params[:id])

    if waypoint.destroy
      render json: waypoint
    else
      render json: { errors: "Unable to delete waypoint." }
    end
  end

  private
  def set_tour
    @tour = current_user.tours.find(params[:tour_id])
  end

  def waypoint_params
    params.require(:waypoint).permit(:name, :description, :position, :image, :latitude, :longitude)
  end
end
