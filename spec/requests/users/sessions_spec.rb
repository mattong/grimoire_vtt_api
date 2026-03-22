require 'rails_helper'

RSpec.describe "Users::Sessions", type: :request do
  let!(:user) { create(:user, password: "password123") }

  describe "POST /api/auth/login" do
    it "logs in user with valid credentials" do
      post "/api/auth/login", params: {
        user: {
          username: user.username,
          password: "password123"
        }
      }, as: :json

      expect(response).to have_http_status(:ok)
      expect(json["message"]).to eq("Logged in successfully.")
      expect(json["user"]["username"]).to eq(user.username)
      expect(response.headers["Authorization"]).to be_present
    end

    it "returns unauthorized with invalid credentials" do
      post "/api/auth/login", params: {
        user: {
          username: user.username,
          password: "wrongpassword"
        }
      }, as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(json["error"]).to eq("Invalid username or password.")
    end
  end

  describe "DELETE /api/auth/logout" do
    it "logs out a logged in user" do
      post "/api/auth/login", params: {
        user: {
          username: user.username,
          password: "password123"
        }
      }, as: :json

      token = response.headers["Authorization"]

      delete "/api/auth/logout", headers: { "Authorization" => token }, as: :json

      expect(response).to have_http_status(:ok)
      expect(json["message"]).to eq("Logged out successfully.")
      expect(response.headers["Authorization"]).to be_nil
    end
  end
end
