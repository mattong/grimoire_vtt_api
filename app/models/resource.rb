class Resource < ApplicationRecord
  belongs_to :template
  belongs_to :game
  belongs_to :player, class_name: "User", optional: true

  validates :name, presence: true

  delegate :game, to: :template
end
