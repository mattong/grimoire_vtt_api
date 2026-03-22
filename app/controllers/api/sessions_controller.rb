class Api::SessionsController < ApplicationController
  def create
    @user = User.find_by(username: params[:username])

    if @user&.authenticate(params[:password])
      render json: { user: { id: @user.id, username: @user.username } }, status: :ok
    else
      render json: { error: "Invalid email or password" }, status: :unauthorized
    end
  end
end
