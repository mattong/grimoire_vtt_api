require 'rails_helper'

RSpec.describe "Users::Registrations", type: :request do
  let(:valid_attributes) do
    {
      user: {
        username: "elminster_the_sage",
        password: "mystra123",
        password_confirmation: "mystra123"
      }
    }
  end

  describe "POST /api/auth/signup" do
    it("creates a new User and returns the user data") do
      expect {
        post "/api/auth/signup", params: valid_attributes, as: :json
      }.to change(User, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(json["message"]).to eq("Signed up successfully.")
      expect(json["user"]["username"]).to eq("elminster_the_sage")

      expect(response.headers["Authorization"]).to be_present
      expect(response.headers["Authorization"]).to match(/^Bearer /)
    end

    it("returns error message with invalid parameters") do
      expect {
        post "/api/auth/signup",
             params: {
               user: {
                 username: "",
                 password: "short",
                 password_confirmation: "short"
               }
             },
             as: :json
      }.not_to change(User, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["errors"]).to include("Username can't be blank")
      expect(json["errors"]).to include("Password is too short (minimum is 6 characters)")
    end

    it("returns error message if username is already taken") do
      create(:user, username: "elminster_the_sage")

      expect {
        post "/api/auth/signup", params: valid_attributes, as: :json
      }.not_to change(User, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["errors"]).to include("Username has already been taken")
    end

    it "returns error message if password_confirmation does not match password" do
      expect {
        post "/api/auth/signup",
             params: {
               user: {
                 username: "elminster_the_sage",
                 password: "mystra123",
                 password_confirmation: "wrong_password"
               }
             },
             as: :json
      }.not_to change(User, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["errors"]).to include("Password confirmation doesn't match Password")
    end
  end
end
