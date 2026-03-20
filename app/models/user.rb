class User < ApplicationRecord
  has_secure_password

  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :username, presence: true, uniqueness: true

  has_many :game_memberships
  has_many :games, through: :game_memberships
end
