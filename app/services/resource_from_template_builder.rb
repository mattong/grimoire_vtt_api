class ResourceFromTemplateBuilder
  Result = Struct.new(:success?, :resource, :error, :status, keyword_init: true)

  def self.call(template:, current_user:, params:)
    new(template:, current_user:, params:).call
  end

  def initialize(template:, current_user:, params:)
    @template = template
    @current_user = current_user
    @params = params
  end

  def call
    return forbidden_result unless authorized?

    resource = Resource.new(
      resource_template: @template,
      game: @template.game,
      name: @params[:name],
      data: merged_data,
      player: assigned_player
    )

    Result.new(success?: true, resource: resource)
  end

  private

  def authorized?
    return true if @template.creatable_by == "all"
    return false if @template.creatable_by != "gm"

    @template.game.gm?(@current_user)
  end

  def forbidden_result
    Result.new(
      success?: false,
      error: "You are not authorized to create resources from this template",
      status: :forbidden
    )
  end

  def merged_data
    defaults = {}
    fields = @template.schema&.dig("fields") || []
    fields.each do |field|
      defaults[field["field_key"]] = nil
    end
    provided = @params[:data] || {}
    defaults.deep_merge(provided)
  end

  def assigned_player
    if @params[:player_id].present? && @template.game.gm?(@current_user)
      User.find_by(id: @params[:player_id])
    else
      @current_user
    end
  end
end
