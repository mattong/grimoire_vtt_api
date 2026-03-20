class Api::GamesController < ApplicationController
  before_action :set_game, only: [:show, :update, :destroy]
  def index
    @games = Game.all
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
    user = User.find(params[:user_id])
    @game = Game.new(game_params)

    # Equivalent to Ecto.Multi
    ActiveRecord::Base.transaction do
      if @game.save
        @game.game_memberships.create!(user: user, role: :gm)
        render json: @game, status: :created
      else
        render json: { errors: @game.errors.full_messages }, status: :unprocessable_content
      end
    end
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_content
  end

  private

  def game_params
    params.require(:game).permit(:title, :system, :description)
  end

  def set_game
    @game = Game.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Game not found" }, status: :not_found
  end
end
