require 'rails_helper'

RSpec.describe "Api::Users", type: :request do
  describe "POST /api/auth/register" do
    let(:valid_attributes) do
      {
        user: {
          email: "elminster@wizardtower.com",
          username: "elminster_the_sage",
          password: "mystra123",
          password_confirmation: "mystra123"
        }
      }
    end

    context "with valid parameters" do
      it "creates a new User and returns the user data" do
        expect {
          post "/api/auth/register", params: valid_attributes, as: :json
        }.to change(User, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(json["user"]["email"]).to eq("elminster@wizardtower.com")
        expect(json["user"]["username"]).to eq("elminster_the_sage")
        expect(json["user"]).not_to have_key("password_digest")
      end
    end

    context "with invalid parameters" do
      it("does not create a new User and returns error messages") do
        expect {
          post "/api/auth/register", params: { user: { email: "", username: "", password: "short", password_confirmation: "short" } }, as: :json
        }.not_to change(User, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(json["errors"]).to include("Email can't be blank")
        expect(json["errors"]).to include("Username can't be blank")
      end
    end
  end
end
