require 'rails_helper'

RSpec.describe Resource, type: :model do
  describe 'associations' do
    it 'belongs to a resource_template' do
      association = described_class.reflect_on_association(:resource_template)
      expect(association.macro).to eq(:belongs_to)
    end

    it 'belongs to a game' do
      association = described_class.reflect_on_association(:game)
      expect(association.macro).to eq(:belongs_to)
    end

    it 'belongs to a player (optional)' do
      association = described_class.reflect_on_association(:player)
      expect(association.macro).to eq(:belongs_to)
      expect(association.options[:optional]).to be(true)
    end
  end

  describe 'validations' do
    it 'is valid with a name' do
      resource = build(:resource, name: "Gandalf")
      expect(resource).to be_valid
    end

    it 'is invalid without a name' do
      resource = build(:resource, name: nil)
      expect(resource).not_to be_valid
      expect(resource.errors[:name]).to include("can't be blank")
    end
  end

  describe 'scopes' do
    let!(:game) { create(:game) }
    let!(:gm) { create(:user) }
    let!(:active_resource) { create(:resource, game: game) }
    let!(:archived_resource) { create(:resource, game: game, archived_at: 1.day.ago) }

    before do
      create(:game_membership, user: gm, game: game, role: :gm)
    end

    it 'returns only active (non-archived) resources' do
      expect(described_class.active).to include(active_resource)
      expect(described_class.active).not_to include(archived_resource)
    end
  end
end
