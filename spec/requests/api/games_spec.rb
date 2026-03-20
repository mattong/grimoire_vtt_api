require 'rails_helper'

RSpec.describe "Api::Games", type: :request do
  let!(:user) { create(:user) }
  let(:valid_attributes) do
    {
      game: {
        title: "Epic Adventure",
        description: "An epic adventure game for testing.",
        system: "D&D 5e"
      },
      user_id: user.id
    }
  end

  describe "POST /api/games" do
    context "with valid parameters" do
      it "creates a new Game and returns the game data" do
        expect {
          post "/api/games", params: valid_attributes, as: :json
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
               params: { game: { title: "", description: "", system: "" } },
               as: :json
        }.not_to change(Game, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(json["errors"]).to include("Title can't be blank")
      end
    end
  end

  describe "Games methods" do
    let!(:game) { create(:game) }

    it "returns a list of games" do
      get "/api/games", as: :json

      expect(response).to have_http_status(:ok)
      expect(json).to be_an(Array)
      expect(json.first["title"]).to eq(game.title)
    end

    it "returns a specific game" do
      get "/api/games/#{game.id}", as: :json

      expect(response).to have_http_status(:ok)
      expect(json["title"]).to eq(game.title)
    end

    it "returns not found for non-existent game" do
      get "/api/games/9999", as: :json

      expect(response).to have_http_status(:not_found)
      expect(json["error"]).to eq("Game not found")
    end

    it "updates a game" do
      patch "/api/games/#{game.id}",
            params: { game: { title: "Updated Title" } },
            as: :json

      expect(response).to have_http_status(:ok)
      expect(json["title"]).to eq("Updated Title")
    end

    it "deletes (archives) a game" do
      delete "/api/games/#{game.id}", as: :json

      expect(response).to have_http_status(:ok)
      expect(json["message"]).to eq("Game archived successfully")
      expect(json["archived_at"]).not_to be_nil
    end
  end
end
