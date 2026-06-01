module GameAuthenticatable
  extend ActiveSupport::Concern

  included do
  end

  private

  def set_game
    @game = current_user.games.active.includes(game_memberships: :user)
                      .find_by!(slug: params[:game_id] || params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Game not found" }, status: :not_found
  end

  def ensure_gm!
    unless @game.gm?(current_user)
      render json: { error: "Only a GM can do that!" }, status: :forbidden
    end
  end
end
