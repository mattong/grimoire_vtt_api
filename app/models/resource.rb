class Resource < ApplicationRecord
  include Sluggable
  friendly_id :name, use: [:scoped, :sequentially_slugged], scope: :game_id

  belongs_to :resource_template
  belongs_to :game
  belongs_to :player, class_name: "User", optional: true

  validates :name, presence: true

  scope :active, -> { where(archived_at: nil) }
end
