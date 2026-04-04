require 'rails_helper'

RSpec.describe Resource, type: :model do
  describe 'basic model behavior' do
    it 'can be instantiated' do
      expect(described_class.new).to be_a(described_class)
    end
  end
end
