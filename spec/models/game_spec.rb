require 'rails_helper'

RSpec.describe Game, type: :model do
  describe "validations" do
    it("requires a title") do
      game = Game.new(title: nil)

      expect(game).not_to be_valid
      expect(game.errors[:title]).to include("can't be blank")
    end
  end
end
