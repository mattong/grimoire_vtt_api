class GameSerializer
  include Alba::Resource
  attributes :id, :title, :description, :system, :created_at

  many :game_memberships, serializer: GameMembershipSerializer
end
