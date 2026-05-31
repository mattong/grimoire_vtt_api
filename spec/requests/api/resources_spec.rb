require 'rails_helper'

RSpec.describe "Api::Resources", type: :request do
  let!(:gm) { create(:user) }
  let!(:player) { create(:user) }
  let!(:other_player) { create(:user) }
  let(:gm_headers) { auth_headers(gm) }
  let(:player_headers) { auth_headers(player) }
  let(:other_player_headers) { auth_headers(other_player) }
  let(:game) { create(:game) }

  let!(:template) do
    create(:resource_template, game: game, schema: {
      "fields" => [
        { "field_key" => "name", "label" => "Name", "input_type" => "text" },
        { "field_key" => "hp", "label" => "HP", "input_type" => "number" }
      ]
    })
  end

  let(:valid_create_params) do
    {
      resource: {
        name: "Gandalf",
        data: { "name" => "Gandalf", "hp" => 100 }
      }
    }
  end

  before do
    create(:game_membership, user: gm, game: game, role: :gm)
    create(:game_membership, user: player, game: game, role: :player)
    create(:game_membership, user: other_player, game: game, role: :player)
  end

  describe "POST /api/games/:game_id/resource_templates/:template_id/resources" do
    context "when creatable_by is 'gm'" do
      before { template.update!(creatable_by: "gm") }

      it "creates a resource for a GM" do
        expect {
          post "/api/games/#{game.slug}/resource_templates/#{template.slug}/resources",
               params: valid_create_params, headers: gm_headers, as: :json
        }.to change(Resource, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(json["name"]).to eq("Gandalf")
        expect(json["data"]["hp"]).to eq(100)
      end

      it "rejects a player" do
        expect {
          post "/api/games/#{game.slug}/resource_templates/#{template.slug}/resources",
               params: valid_create_params, headers: player_headers, as: :json
        }.not_to change(Resource, :count)

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when creatable_by is 'all'" do
      before { template.update!(creatable_by: "all") }

      it "creates a resource for a player" do
        expect {
          post "/api/games/#{game.slug}/resource_templates/#{template.slug}/resources",
               params: valid_create_params, headers: player_headers, as: :json
        }.to change(Resource, :count).by(1)

        expect(response).to have_http_status(:created)
      end
    end

    context "with invalid data" do
      it "returns 422 when name is missing" do
        post "/api/games/#{game.slug}/resource_templates/#{template.slug}/resources",
             params: { resource: { name: "", data: {} } },
             headers: gm_headers, as: :json

        expect(response).to have_http_status(:unprocessable_content)
        expect(json["errors"]).to include("Name can't be blank")
      end
    end
  end

  describe "GET /api/games/:game_id/resources" do
    let!(:resource1) { create(:resource, game: game, name: "Aragorn", player: player) }
    let!(:resource2) { create(:resource, game: game, name: "Legolas", player: other_player) }
    let!(:archived_resource) { create(:resource, game: game, name: "Archived", archived_at: 1.day.ago) }
    let!(:other_game_resource) { create(:resource, name: "Sauron") }

    it "returns all active resources for the game" do
      get "/api/games/#{game.slug}/resources", headers: player_headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(json.size).to eq(2)
      expect(json.map { |r| r["name"] }).to include("Aragorn", "Legolas")
    end

    it "returns 404 for non-member" do
      non_member = create(:user)
      non_member_headers = auth_headers(non_member)

      get "/api/games/#{game.slug}/resources", headers: non_member_headers, as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /api/games/:game_id/resources/:id" do
    let!(:resource) { create(:resource, game: game, name: "Gandalf", player: player) }

    it "returns the resource for a game member" do
      get "/api/games/#{game.slug}/resources/#{resource.slug}", headers: player_headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(json["name"]).to eq("Gandalf")
    end

    it "returns 404 for non-member" do
      non_member = create(:user)
      non_member_headers = auth_headers(non_member)

      get "/api/games/#{game.slug}/resources/#{resource.slug}", headers: non_member_headers, as: :json

      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for archived resource" do
      archived = create(:resource, game: game, archived_at: 1.day.ago)

      get "/api/games/#{game.slug}/resources/#{archived.slug}", headers: player_headers, as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /api/games/:game_id/resources/:id" do
    let!(:resource) { create(:resource, game: game, name: "Gandalf", player: player) }

    context "when GM updates" do
      it "updates the resource" do
        patch "/api/games/#{game.slug}/resources/#{resource.slug}",
              params: { resource: { name: "Gandalf the White" } },
              headers: gm_headers, as: :json

        expect(response).to have_http_status(:ok)
        expect(json["name"]).to eq("Gandalf the White")
      end
    end

    context "when owning player updates" do
      it "updates the resource" do
        patch "/api/games/#{game.slug}/resources/#{resource.slug}",
              params: { resource: { name: "Gandalf the Grey" } },
              headers: player_headers, as: :json

        expect(response).to have_http_status(:ok)
        expect(json["name"]).to eq("Gandalf the Grey")
      end
    end

    context "when non-owning player updates" do
      it "returns 403" do
        patch "/api/games/#{game.slug}/resources/#{resource.slug}",
              params: { resource: { name: "Gandalf the White" } },
              headers: other_player_headers, as: :json

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "DELETE /api/games/:game_id/resources/:id" do
    let!(:resource) { create(:resource, game: game, name: "Gandalf", player: player) }

    context "when GM archives" do
      it "soft-deletes the resource" do
        delete "/api/games/#{game.slug}/resources/#{resource.slug}", headers: gm_headers, as: :json

        expect(response).to have_http_status(:ok)
        expect(json["message"]).to eq("Resource archived successfully")
        expect(resource.reload.archived_at).not_to be_nil
      end
    end

    context "when owning player archives" do
      it "soft-deletes the resource" do
        delete "/api/games/#{game.slug}/resources/#{resource.slug}", headers: player_headers, as: :json

        expect(response).to have_http_status(:ok)
        expect(resource.reload.archived_at).not_to be_nil
      end
    end

    context "when non-owning player archives" do
      it "returns 403" do
        delete "/api/games/#{game.slug}/resources/#{resource.slug}", headers: other_player_headers, as: :json

        expect(response).to have_http_status(:forbidden)
        expect(resource.reload.archived_at).to be_nil
      end
    end
  end
end
