class Api::SessionsController < ApplicationController
  def create
    @user = User.find_by(email: params[:email])

    if @user&.authenticate(params[:password])
      render json: { user: { id: @user.id, email: @user.email, username: @user.username } }, status: :ok
    else
      render json: { error: "Invalid email or password" }, status: :unauthorized
    end
  end
end
