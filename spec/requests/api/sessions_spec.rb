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
             params: { email: user.email, password: "mystra123" },
             as: :json

        expect(response).to have_http_status(:ok)
        expect(json["user"]["email"]).to eq(user.email)
        expect(json["user"]["username"]).to eq(user.username)
        expect(json["user"]).not_to have_key("password_digest")
      end
    end

    context "with invalid credentials" do
      it "returns an error message" do
        post "/api/auth/login",
             params: { email: user.email, password: "wrongpassword" },
             as: :json

        expect(response).to have_http_status(:unauthorized)
        expect(json["error"]).to eq("Invalid email or password")
      end

      it "returns unauthorized when email is not found" do
        post "/api/auth/login",
             params: {
               email: "mysteriousman@example.com",
               password: "idonotexist"
             },
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
