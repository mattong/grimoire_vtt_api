class Users::SessionsController < Devise::SessionsController
  respond_to :json

  private

  def respond_with(resource, _opts = {})
    render json: { message: "Logged in successfully.", user: { username: resource.username } }, status: :ok
  end

  def respond_to_on_destroy(_resource)
    render json: { message: "Logged out successfully." }, status: :ok
  end
end
