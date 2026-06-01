require 'rails_helper'

RSpec.describe ResourceFromTemplateBuilder, type: :service do
  describe '.call' do
    let!(:game) { create(:game) }
    let!(:gm) { create(:user) }
    let!(:player) { create(:user) }
    let!(:template) do
      create(:resource_template, game: game, schema: {
        "fields" => [
          { "field_key" => "name", "label" => "Name", "input_type" => "text" },
          { "field_key" => "hp", "label" => "Hit Points", "input_type" => "number" },
          { "field_key" => "is_ally", "label" => "Is Ally", "input_type" => "checkbox" }
        ]
      })
    end

    before do
      create(:game_membership, user: gm, game: game, role: :gm)
      create(:game_membership, user: player, game: game, role: :player)
    end

    context 'when creatable_by is "gm"' do
      before { template.update!(creatable_by: "gm") }

      it 'allows GM to create a resource' do
        result = described_class.call(template: template, current_user: gm, params: {})
        expect(result).to be_success
        expect(result.resource).to be_a(Resource)
        expect(result.resource).not_to be_persisted
      end

      it 'rejects a non-GM player' do
        result = described_class.call(template: template, current_user: player, params: {})
        expect(result).not_to be_success
        expect(result.status).to eq(:forbidden)
        expect(result.error).to be_present
      end
    end

    context 'when creatable_by is "all"' do
      before { template.update!(creatable_by: "all") }

      it 'allows a player to create a resource' do
        result = described_class.call(template: template, current_user: player, params: {})
        expect(result).to be_success
        expect(result.resource).to be_a(Resource)
      end

      it 'allows a GM to create a resource' do
        result = described_class.call(template: template, current_user: gm, params: {})
        expect(result).to be_success
      end
    end

    describe 'data defaults' do
      it 'pre-populates data from schema fields with nil defaults' do
        result = described_class.call(template: template, current_user: gm, params: {})
        expect(result.resource.data).to eq({ "name" => nil, "hp" => nil, "is_ally" => nil })
      end

      it 'merges client-provided data over the defaults' do
        result = described_class.call(
          template: template,
          current_user: gm,
          params: { data: { "name" => "Gandalf", "hp" => 100 } }
        )
        expect(result.resource.data["name"]).to eq("Gandalf")
        expect(result.resource.data["hp"]).to eq(100)
        expect(result.resource.data["is_ally"]).to be_nil
      end
    end

    describe 'player assignment' do
      before { template.update!(creatable_by: "all") }

      it 'defaults player_id to current_user' do
        result = described_class.call(template: template, current_user: player, params: {})
        expect(result.resource.player).to eq(player)
      end

      it 'allows GM to override player_id' do
        other_user = create(:user)
        create(:game_membership, user: other_user, game: game, role: :player)
        result = described_class.call(
          template: template,
          current_user: gm,
          params: { player_id: other_user.id }
        )
        expect(result.resource.player).to eq(other_user)
      end

      it 'ignores player_id override from non-GM' do
        other_user = create(:user)
        result = described_class.call(
          template: template,
          current_user: player,
          params: { player_id: other_user.id }
        )
        expect(result.resource.player).to eq(player)
      end
    end
  end
end
