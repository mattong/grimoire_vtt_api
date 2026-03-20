class GameMembership < ApplicationRecord
  belongs_to :user
  belongs_to :game

  enum :role, { player: "player", gm: "gm" }

  validates :user_id, uniqueness: { scope: :game_id, message: "is already in this game" }
end
