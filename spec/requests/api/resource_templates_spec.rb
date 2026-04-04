require 'rails_helper'

RSpec.describe "Api::ResourceTemplates", type: :request do
  let!(:gm) { create(:user) }
  let!(:player) { create(:user) }
  let(:gm_headers) { auth_headers(gm) }
  let(:player_headers) { auth_headers(player) }
  let(:game) { create(:game) }




  let(:valid_attributes) do
    {
      resource_template: {
        name: "Character Sheet",
        template_type: "character",
        schema: {
          "fields" => [
            { "field_key" => "name", "label" => "Name", "input_type" => "text" },
            { "field_key" => "hp", "label" => "Hit Points", "input_type" => "number" }
          ]
        }
      }
    }
  end

  before do
    create(:game_membership, user: gm, game: game, role: :gm)
    create(:game_membership, user: player, game: game, role: :player)
  end

  describe "POST /api/games/:game_id/resource_templates" do
    context "with valid parameters and gm authentication" do
      it "creates a new ResourceTemplate and returns the template data" do
        expect {
          post "/api/games/#{game.id}/resource_templates", params: valid_attributes, headers: gm_headers, as: :json
        }.to change(ResourceTemplate, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(json["name"]).to eq("Character Sheet")
        expect(json["template_type"]).to eq("character")
        expect(json["schema"]["fields"].size).to eq(2)
      end
    end

    context "with valid parameters and player authentication" do
      it "does not create a new ResourceTemplate and returns an error" do
        expect {
          post "/api/games/#{game.id}/resource_templates", params: valid_attributes, headers: player_headers, as: :json
        }.not_to change(ResourceTemplate, :count)

        expect(response).to have_http_status(:forbidden)
        expect(json["error"]).to eq("Only a GM can do that!")
      end
    end

    context "with invalid parameters" do
      it "does not create a new ResourceTemplate and returns error messages" do
        expect {
          post "/api/games/#{game.id}/resource_templates",
               params: { resource_template: { name: "", template_type: "", schema: {} } },
               headers: gm_headers,
               as: :json
        }.not_to change(ResourceTemplate, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(json["errors"]).to include("Name can't be blank")
      end
    end

    context "without authentication" do
      it "returns an unauthorized error" do
        post "/api/games/#{game.id}/resource_templates", params: valid_attributes, as: :json

        expect(response).to have_http_status(:unauthorized)
        expect(json["error"]).to eq("You need to sign in or sign up before continuing.")
      end
    end
  end

  describe "GET /api/games/:game_id/resource_templates" do
    let!(:other_game) { create(:game) }
    before do
      create(:resource_template, game: game, name: "Character Sheet 1")
      create(:resource_template, game: game, name: "NPC 1", template_type: "npc")
      create(:resource_template, game: game, name: "Archived Sheet", archived_at: 1.day.ago)
      create(:resource_template, game: other_game, name: "Unrelated Template")
    end

    context "with gm authentication" do
      it "returns a list of non-archived resource templates for the game" do
        get "/api/games/#{game.id}/resource_templates", headers: gm_headers, as: :json

        expect(response).to have_http_status(:ok)
        expect(json.size).to eq(2)
        expect(json.map { |t| t["name"] }).to include("Character Sheet 1", "NPC 1")
      end
    end

    context "with player authentication" do
      it "returns a list of non-archived resource templates for the game" do
        get "/api/games/#{game.id}/resource_templates", headers: player_headers, as: :json

        expect(response).to have_http_status(:ok)
        expect(json.size).to eq(2)
        expect(json.map { |t| t["name"] }).to include("Character Sheet 1", "NPC 1")
      end
    end
  end

  describe "GET /api/games/:game_id/resource_templates/:id" do
    let!(:other_game) { create(:game) }
    let!(:resource_template) { create(:resource_template, game: game, name: "Character Sheet 1") }
    let!(:archived_template) { create(:resource_template, game: game, name: "Archived Sheet", archived_at: 1.day.ago) }
    let!(:other_template) { create(:resource_template, game: other_game, name: "Unrelated Template") }

    context "with gm authentication" do
      it "returns the resource template data if it belongs to the game and is not archived" do
        get "/api/games/#{game.id}/resource_templates/#{resource_template.id}", headers: gm_headers, as: :json

        expect(response).to have_http_status(:ok)
        expect(json["name"]).to eq("Character Sheet 1")
      end

      it "returns a not found error if the template is archived" do
        get "/api/games/#{game.id}/resource_templates/#{archived_template.id}", headers: gm_headers, as: :json

        expect(response).to have_http_status(:not_found)
        expect(json["error"]).to eq("Resource template not found")
      end

      it "returns a not found error if the template does not belong to the game" do
        get "/api/games/#{game.id}/resource_templates/#{other_template.id}", headers: gm_headers, as: :json

        expect(response).to have_http_status(:not_found)
        expect(json["error"]).to eq("Resource template not found")
      end
    end

    context "with player authentication" do
      it "returns the resource template data if it belongs to the game and is not archived" do
        get "/api/games/#{game.id}/resource_templates/#{resource_template.id}", headers: player_headers, as: :json

        expect(response).to have_http_status(:ok)
        expect(json["name"]).to eq("Character Sheet 1")
      end
    end
  end

  describe "PATCH /api/games/:game_id/resource_templates/:id" do
    let!(:resource_template) { create(:resource_template, game: game, name: "Character Sheet 1") }

    context "with gm authentication" do
      it "updates the resource template and returns the updated data" do
        patch "/api/games/#{game.id}/resource_templates/#{resource_template.id}",
              params: { resource_template: { name: "Updated Name" } },
              headers: gm_headers,
              as: :json

        expect(response).to have_http_status(:ok)
        expect(json["name"]).to eq("Updated Name")
      end
    end

    context "with player authentication" do
      it "does not update the resource template and returns an error" do
        patch "/api/games/#{game.id}/resource_templates/#{resource_template.id}",
              params: { resource_template: { name: "Updated Name" } },
              headers: player_headers,
              as: :json

        expect(response).to have_http_status(:forbidden)
        expect(json["error"]).to eq("Only a GM can do that!")
      end
    end
  end

  describe "DELETE /api/games/:game_id/resource_templates/:id" do
    let!(:resource_template) { create(:resource_template, game: game, name: "Character Sheet 1") }

    context "with gm authentication" do
      it "archives the resource template and returns a success message" do
        delete "/api/games/#{game.id}/resource_templates/#{resource_template.id}", headers: gm_headers, as: :json

        expect(response).to have_http_status(:ok)
        expect(json["message"]).to eq("Resource template archived successfully")
        expect(json["archived_at"]).not_to be_nil
        expect(resource_template.reload.archived_at).not_to be_nil
      end
    end

    context "with player authentication" do
      it "does not archive the resource template and returns an error" do
        delete "/api/games/#{game.id}/resource_templates/#{resource_template.id}", headers: player_headers, as: :json

        expect(response).to have_http_status(:forbidden)
        expect(json["error"]).to eq("Only a GM can do that!")
        expect(resource_template.reload.archived_at).to be_nil
      end
    end
  end
end
