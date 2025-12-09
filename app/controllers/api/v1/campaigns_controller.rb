class Api::V1::CampaignsController < ApplicationController
  before_action :set_campaign, only: [:show, :update, :destroy]

  def index
    page     = params[:page].to_i > 0 ? params[:page].to_i : 1
    per_page = params[:per_page].to_i > 0 ? params[:per_page].to_i : 20
    scope    = Campaign.order(id: :desc)
    scope    = scope.text_search(params[:query]) if params[:query].present?
    scope    = scope.merge(Campaign.ransack(params[:q]).result) if params[:q].present?

    items = scope.offset((page - 1) * per_page).limit(per_page)
    render json: { data: items.as_json(only: %i[id name status starts_on ends_on]), pagination: { page: page, per_page: per_page, total: scope.count } }
  end

  def show
    render json: { data: @campaign.attributes }
  end

  def create
    c = Campaign.new(campaign_params)
    if c.save
      render json: { data: c.attributes }, status: :created
    else
      render json: { errors: c.errors }, status: :unprocessable_entity
    end
  end

  def update
    if @campaign.update(campaign_params)
      render json: { data: @campaign.attributes }
    else
      render json: { errors: @campaign.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    @campaign.destroy
    render json: { status: 'ok' }
  end

  private

  def set_campaign
    @campaign = Campaign.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Campaign not found' }, status: :not_found
  end

  def campaign_params
    params.require(:campaign).permit(:name, :status, :budget, :target_leads, :target_conversion, :target_revenue, :starts_on, :ends_on, :access, :assigned_to, :user_id, :background_info)
  end
end