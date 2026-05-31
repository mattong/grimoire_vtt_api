class Game < ApplicationRecord
  include Sluggable
  friendly_id :title, use: [:scoped, :sequentially_slugged], scope: :gm_id

  belongs_to :gm, class_name: "User"

  has_many :game_memberships
  has_many :users, through: :game_memberships

  has_many :resource_templates, dependent: :destroy
  has_many :resources, dependent: :destroy

  validates :title, presence: true

  scope :active, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }

  def gm?(user)
    game_memberships.exists?(user: user, role: "gm")
  end
end
