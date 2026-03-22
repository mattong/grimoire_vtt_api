require 'rails_helper'

RSpec.describe "Api::Sessions", type: :request do
  let!(:user) do
    create(
      :user,
      password: "mystra123",
      password_confirmation: "mystra123"
    )
  end

  describe "POST /api/auth/login" do
    context "with valid credentials" do
      it "returns the user data" do
        post "/api/auth/login",
             params: { username: user.username, password: "mystra123" },
             as: :json

        expect(response).to have_http_status(:ok)
        expect(json["user"]["username"]).to eq(user.username)
        expect(json["user"]).not_to have_key("password_digest")
      end
    end

    context "with invalid credentials" do
      it "returns an error message" do
        post "/api/auth/login",
             params: { username: user.username, password: "wrongpassword" },
             as: :json

        expect(response).to have_http_status(:unauthorized)
        expect(json["error"]).to eq("Invalid username or password")
      end

      it "returns unauthorized when username is not found" do
        post "/api/auth/login",
             params: {
               username: "mysteriousman@example.com",
               password: "idonotexist"
             },
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
