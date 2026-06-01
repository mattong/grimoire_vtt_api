class Api::ResourceTemplatesController < ApplicationController
  include GameAuthenticatable
  before_action :authenticate_user!
  before_action :set_game
  before_action :set_template, only: [:show, :update, :destroy]
  before_action :ensure_gm!, except: [:index, :show]

  def index
    @templates = @game.resource_templates.active
    render json: ResourceTemplateSerializer.new(@templates).serialize, status: :ok
  end

  def show
    render json: ResourceTemplateSerializer.new(@template).serialize, status: :ok
  end

  def create
    @template = @game.resource_templates.new(resource_template_params)
    if @template.save
      render json: ResourceTemplateSerializer.new(@template).serialize, status: :created
    else
      render json: { errors: @template.errors.full_messages }, status: :unprocessable_content
    end
  end

  def update
    if @template.update(resource_template_params)
      render json: ResourceTemplateSerializer.new(@template).serialize, status: :ok
    else
      render json: { errors: @template.errors.full_messages }, status: :unprocessable_content
    end
  end

  def destroy
    if @template.update(archived_at: Time.current)
      render json: { message: "Resource template archived successfully", archived_at: @template.archived_at }, status: :ok
    else
      render json: { errors: ["Could not archive resource template"] }, status: :unprocessable_content
    end
  end

  private

  def set_template
    @template = @game.resource_templates.active.find_by!(slug: params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Resource template not found" }, status: :not_found
  end

  def resource_template_params
    params.require(:resource_template).permit(:name, :template_type, schema: {})
  end
end
