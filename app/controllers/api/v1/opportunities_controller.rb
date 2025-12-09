class Api::V1::OpportunitiesController < ApplicationController
  before_action :set_opportunity, only: [:show, :update, :destroy]

  def index
    page     = params[:page].to_i > 0 ? params[:page].to_i : 1
    per_page = params[:per_page].to_i > 0 ? params[:per_page].to_i : 20
    scope    = Opportunity.order(id: :desc)
    scope    = scope.text_search(params[:query]) if params[:query].present?
    scope    = scope.merge(Opportunity.ransack(params[:q]).result) if params[:q].present?

    items = scope.offset((page - 1) * per_page).limit(per_page)
    render json: { data: items.as_json(only: %i[id name stage amount probability closes_on]), pagination: { page: page, per_page: per_page, total: scope.count } }
  end

  def show
    render json: { data: @opportunity.attributes }
  end

  def create
    # payload may include nested account/campaign/contact references like the UI does
    opp = Opportunity.new(opportunity_params)
    if opp.save_with_account_and_permissions(params.permit!.to_h)
      render json: { data: opp.attributes }, status: :created
    else
      render json: { errors: opp.errors }, status: :unprocessable_entity
    end
  end

  def update
    if @opportunity.update_with_account_and_permissions(params.permit!.to_h)
      render json: { data: @opportunity.attributes }
    else
      render json: { errors: @opportunity.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    @opportunity.destroy
    render json: { status: 'ok' }
  end

  private

  def set_opportunity
    @opportunity = Opportunity.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Opportunity not found' }, status: :not_found
  end

  def opportunity_params
    params.require(:opportunity).permit(:name, :access, :source, :stage, :probability, :amount, :discount, :closes_on, :assigned_to, :user_id, :campaign_id, :background_info)
  end
end