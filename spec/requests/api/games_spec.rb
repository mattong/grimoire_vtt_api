require 'rails_helper'

RSpec.describe "Api::Games", type: :request do
  let!(:user) { create(:user) }
  let(:headers) { auth_headers(user) }
  let(:valid_attributes) do
    {
      game: {
        title: "Epic Adventure",
        description: "An epic adventure game for testing.",
        system: "D&D 5e"
      }
    }
  end

  describe "POST /api/games" do
    context "with valid parameters" do
      it "creates a new Game and returns the game data" do
        expect {
          post "/api/games", params: valid_attributes, headers: headers, as: :json
        }.to change(Game, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(json["title"]).to eq("Epic Adventure")
        expect(json["description"]).to eq("An epic adventure game for testing.")
        expect(json["system"]).to eq("D&D 5e")

        game_membership = GameMembership.last

        expect(game_membership.user_id).to eq(user.id)
        expect(game_membership.game_id).to eq(Game.last.id)
        expect(game_membership.role).to eq("gm")
      end
    end

    context "with invalid parameters" do
      it "does not create a new Game and returns error messages" do
        expect {
          post "/api/games",
               params: { game: { title: "", description: "", system: "" }, user_id: user.id  },
               headers: headers,
               as: :json
        }.not_to change(Game, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(json["errors"]).to include("Title can't be blank")
      end
    end

    context "without authentication" do
      it "returns an unauthorized error" do
        post "/api/games", params: valid_attributes, as: :json

        expect(response).to have_http_status(:unauthorized)
        expect(json["error"]).to eq("You need to sign in or sign up before continuing.")
      end
    end
  end

  describe "GET /api/games" do
    let!(:other_user) { create(:user) }
    let!(:user_game) { create(:game, title: "User's Game") }
    let!(:other_game) { create(:game, title: "Other User's Game") }
    let!(:archived_game) { create(:game, title: "Archived Game", archived_at: 1.day.ago) }

    before do
      create(:game_membership, user: user, game: user_game, role: "gm")
      create(:game_membership, user: other_user, game: other_game, role: "gm")
      create(:game_membership, user: user, game: archived_game, role: "gm")
    end

    it("only returns non-archived games the user is a member of") do
      get "/api/games", headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(json.length).to eq(1)
      expect(json.first["title"]).to eq("User's Game")
    end
  end

  describe "GET /api/games/:id" do
    let!(:other_user) { create(:user) }
    let!(:user_game) { create(:game, title: "User's Game") }
    let!(:other_game) { create(:game, title: "Other User's Game") }
    let!(:archived_game) { create(:game, title: "Archived Game", archived_at: 1.day.ago) }

    before do
      create(:game_membership, user: user, game: user_game, role: "gm")
      create(:game_membership, user: other_user, game: other_game, role: "gm")
      create(:game_membership, user: user, game: archived_game, role: "gm")
    end

    it("only allows access to games the user is a member of") do
      get "/api/games/#{user_game.id}", headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(json["title"]).to eq("User's Game")

      get "/api/games/#{other_game.id}", headers: headers, as: :json

      expect(response).to have_http_status(:not_found)
      expect(json["error"]).to eq("Game not found")
    end

    it("returns not found for non-existent game") do
      get "/api/games/#{SecureRandom.uuid}", headers: headers, as: :json

      expect(response).to have_http_status(:not_found)
      expect(json["error"]).to eq("Game not found")
    end

    it("returns not found for archived game") do
      get "/api/games/#{archived_game.id}", headers: headers, as: :json

      expect(response).to have_http_status(:not_found)
      expect(json["error"]).to eq("Game not found")
    end
  end

  describe "PATCH /api/games/:id" do
    let!(:game) { create(:game, title: "Original Title") }
    let!(:other_user) { create(:user) }
    let!(:other_game) { create(:game, title: "Other Game") }
    let!(:non_gm_user) { create(:user) }

    before do
      create(:game_membership, user: user, game: game, role: "gm")
      create(:game_membership, user: non_gm_user, game: game, role: "player")
      create(:game_membership, user: other_user, game: other_game, role: "gm")
    end

    it "only allows updating games the user is a member of" do
      patch "/api/games/#{game.id}",
            params: { game: { title: "Updated Title" } },
            headers: headers,
            as: :json

      expect(response).to have_http_status(:ok)
      expect(json["title"]).to eq("Updated Title")

      patch "/api/games/#{other_game.id}",
            params: { game: { title: "Hacked Title" } },
            headers: headers,
            as: :json

      expect(response).to have_http_status(:not_found)
      expect(json["error"]).to eq("Game not found")
    end

    it "only allows GMs to update games" do
      patch "/api/games/#{game.id}",
            params: { game: { title: "Player Updated Title" } },
            headers: auth_headers(non_gm_user),
            as: :json

      expect(response).to have_http_status(:forbidden)
      expect(json["error"]).to eq("Only a GM can do that!")
    end
  end

  describe "DELETE /api/games/:id" do
    let!(:game) { create(:game, title: "Game to Archive") }
    let!(:other_user) { create(:user) }
    let!(:other_game) { create(:game, title: "Other Game") }
    let!(:non_gm_user) { create(:user) }

    before do
      create(:game_membership, user: user, game: game, role: "gm")
      create(:game_membership, user: non_gm_user, game: game, role: "player")
      create(:game_membership, user: other_user, game: other_game, role: "gm")
    end

    it "only allows deleting (archiving) games the user is a member of" do
      delete "/api/games/#{game.id}", headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(json["message"]).to eq("Game archived successfully")
      expect(json["archived_at"]).not_to be_nil

      delete "/api/games/#{other_game.id}", headers: headers, as: :json

      expect(response).to have_http_status(:not_found)
      expect(json["error"]).to eq("Game not found")
    end

    it "only allows GMs to archive games" do
      delete "/api/games/#{game.id}", headers: auth_headers(non_gm_user), as: :json

      expect(response).to have_http_status(:forbidden)
      expect(json["error"]).to eq("Only a GM can do that!")
    end
  end
end
