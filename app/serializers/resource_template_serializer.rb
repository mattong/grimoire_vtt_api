class ResourceTemplateSerializer
  include Alba::Resource
  attributes :id, :game_id, :name, :template_type, :schema, :creatable_by
end
