class Game < ApplicationRecord
  has_many :game_memberships
  has_many :users, through: :game_memberships

  validates :title, presence: true
end
