class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable

  include Devise::JWT::RevocationStrategies::JTIMatcher

  devise :database_authenticatable, :registerable, :jwt_authenticatable, jwt_revocation_strategy: self

  validates :username, presence: true, uniqueness: true
  validates :password, presence: true, length: { minimum: 6 }, on: :create
  validates :password, confirmation: true, on: :create

  has_many :game_memberships
  has_many :games, through: :game_memberships

  before_validation :generate_jti, on: :create

  private

  def generate_jti
    self.jti ||= SecureRandom.uuid
  end
end
