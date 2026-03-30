class Api::GamesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_game, only: [:show, :update, :destroy]
  before_action :ensure_gm!, only: [:update, :destroy]
  def index
    # Need to add scoping for games that aren't archived
    @games = current_user.games.active
    render json: @games, status: :ok
  end

  def show
    render json: @game, status: :ok
  end

  def update
    if @game.update(game_params)
      render json: @game, status: :ok
    else
      render json: { errors: @game.errors.full_messages }, status: :unprocessable_content
    end
  end

  def destroy
    if @game.update(archived_at: Time.current)
      render json: { message: "Game archived successfully", archived_at: @game.archived_at }, status: :ok
    else
      render json: { errors: ["Could not archive game"] }, status: :unprocessable_content
    end
  end

  def create
    @game = Game.new(game_params)
    # Equivalent to Ecto.Multi
    ActiveRecord::Base.transaction do
      @game.save!
      @game.game_memberships.create!(user: current_user, role: :gm)
      render json: @game, status: :created
    end
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_content
  end

  private

  def game_params
    params.require(:game).permit(:title, :system, :description)
  end

  def set_game
    @game = current_user.games.active.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Game not found" }, status: :not_found
  end

  def ensure_gm!
    if not @game.gm?(current_user)
      render json: { error: "Only a GM can do that!" }, status: :unauthorized
    end
  end
end
