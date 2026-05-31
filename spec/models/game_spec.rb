require 'rails_helper'

RSpec.describe Game, type: :model do
  describe "validations" do
    it("requires a title") do
      game = Game.new(title: nil)

      expect(game).not_to be_valid
      expect(game.errors[:title]).to include("can't be blank")
    end
  end

  describe "slugs" do
    let(:gm) { create(:user) }

    it "generates a slug from the title on create" do
      game = Game.create!(title: "Curse of Strahd", gm: gm)
      expect(game.slug).to eq("curse-of-strahd")
    end

    it "scopes slug uniqueness by gm_id" do
      game1 = Game.create!(title: "My Campaign", gm: gm)
      game2 = Game.create!(title: "My Campaign", gm: gm)
      expect(game1.slug).to eq("my-campaign")
      expect(game2.slug).to eq("my-campaign-2")
    end

    it "allows same slug for different GMs" do
      gm2 = create(:user)
      game1 = Game.create!(title: "Same Title", gm: gm)
      game2 = Game.create!(title: "Same Title", gm: gm2)
      expect(game1.slug).to eq("same-title")
      expect(game2.slug).to eq("same-title")
    end
  end
end
