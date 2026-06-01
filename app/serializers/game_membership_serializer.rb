class GameMembershipSerializer
  include Alba::Resource
  attributes :id, :user_id, :game_id, :role

  one :user, serializer: UserSerializer
end
