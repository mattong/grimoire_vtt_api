class Api::ResourcesController < ApplicationController
  include GameAuthenticatable
  before_action :authenticate_user!
  before_action :set_game
  before_action :set_resource, only: [:show, :update, :destroy]
  before_action :ensure_owner_or_gm!, only: [:update, :destroy]

  def index
    @resources = @game.resources.active.includes(:resource_template, :player)
    render json: ResourceSerializer.new(@resources).serialize, status: :ok
  end

  def show
    render json: ResourceSerializer.new(@resource).serialize, status: :ok
  end

  def create
    @template = @game.resource_templates.active.find(params[:resource_template_id])

    result = ResourceFromTemplateBuilder.call(
      template: @template,
      current_user: current_user,
      params: resource_params
    )

    if result.success?
      if result.resource.save
        render json: ResourceSerializer.new(result.resource).serialize, status: :created
      else
        render json: { errors: result.resource.errors.full_messages }, status: :unprocessable_content
      end
    else
      render json: { error: result.error }, status: result.status
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Resource template not found" }, status: :not_found
  end

  def update
    if @resource.update(resource_params)
      render json: ResourceSerializer.new(@resource).serialize, status: :ok
    else
      render json: { errors: @resource.errors.full_messages }, status: :unprocessable_content
    end
  end

  def destroy
    if @resource.update(archived_at: Time.current)
      render json: { message: "Resource archived successfully", archived_at: @resource.archived_at }, status: :ok
    else
      render json: { errors: ["Could not archive resource"] }, status: :unprocessable_content
    end
  end

  private

  def set_resource
    @resource = @game.resources.active.includes(:resource_template, :player).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Resource not found" }, status: :not_found
  end

  def ensure_owner_or_gm!
    unless @resource.player == current_user || @game.gm?(current_user)
      render json: { error: "Forbidden" }, status: :forbidden
    end
  end

  def resource_params
    params.require(:resource).permit(:name, :player_id, data: {})
  end
end
