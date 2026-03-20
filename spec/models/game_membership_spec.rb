require 'rails_helper'

RSpec.describe GameMembership, type: :model do
  describe "role enum" do
    it "allows valid roles" do
      expect { create(:game_membership, role: "player") }.not_to raise_error
      expect { create(:game_membership, role: "gm") }.not_to raise_error
    end

    it "raises an error for invalid roles" do
      expect { create(:game_membership, role: "invalid_role") }.to raise_error(ArgumentError)
    end
  end

  describe "associations" do
    it "belongs to a user and game" do
      game_membership = create(:game_membership)

      expect(game_membership.user).to be_present
      expect(game_membership.game).to be_present
    end
  end

  describe "uniqueness" do
    it "prevents a user from joining the same game twice" do
      user = create(:user)
      game = create(:game)
      create(:game_membership, user: user, game: game)

      duplicate_membership = build(:game_membership, user: user, game: game)

      expect(duplicate_membership).not_to be_valid
      expect(duplicate_membership.errors[:user_id]).to include("is already in this game")
    end
  end
end
