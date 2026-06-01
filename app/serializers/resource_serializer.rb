class ResourceSerializer
  include Alba::Resource
  attributes :id, :game_id, :resource_template_id, :player_id, :name, :data, :created_at

  one :resource_template, serializer: ResourceTemplateSerializer
  one :player, serializer: UserSerializer
end
