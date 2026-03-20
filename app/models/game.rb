class Game < ApplicationRecord
  has_many :game_memberships
  has_many :users, through: :game_memberships

  validates :title, presence: true

  scope :active, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }
end
