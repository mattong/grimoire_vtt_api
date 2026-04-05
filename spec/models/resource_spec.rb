require 'rails_helper'

RSpec.describe Resource, type: :model do
  describe 'validations' do
    it 'is invalid without a name' do
      resource = described_class.new(name: nil)

      expect(resource).not_to be_valid
      expect(resource.errors[:name]).to be_present
    end
  end

  describe 'associations' do
    it 'defines belongs_to associations for resource_template, game, and player' do
      belongs_to_names = described_class.reflect_on_all_associations(:belongs_to).map(&:name)

      expect(belongs_to_names).to include(:resource_template, :game, :player)
    end
  end
end
