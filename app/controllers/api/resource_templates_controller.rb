class Api::ResourceTemplatesController < ApplicationController
  include GameAuthenticatable
  before_action :authenticate_user!
  before_action :set_game
  before_action :set_template, only: [:show, :update, :destroy]
  before_action :ensure_gm!, except: [:index, :show]

  def index
    @templates = @game.resource_templates
    render json: @templates, status: :ok
  end

  private

  def set_template
    @template = @game.resource_templates.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Resource template not found" }, status: :not_found
  end

  def resource_template_params
    params.require(:resource_template).permit(:name, :template_type, schema: {})
  end
end
