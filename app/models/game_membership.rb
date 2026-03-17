class GameMembership < ApplicationRecord
  belongs_to :user
  belongs_to :game

  enum :role, { player: "player", gm: "gm" }
end
