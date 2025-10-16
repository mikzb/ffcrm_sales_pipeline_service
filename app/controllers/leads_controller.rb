class Api::V1::LeadsController < ApplicationController
  before_action :set_lead, only: [:show, :update, :destroy, :promote, :reject]

  def index
    page     = params[:page].to_i > 0 ? params[:page].to_i : 1
    per_page = params[:per_page].to_i > 0 ? params[:per_page].to_i : 20
    scope    = Lead.order(id: :desc)
    scope    = scope.text_search(params[:query]) if params[:query].present?
    scope    = scope.merge(Lead.ransack(params[:q]).result) if params[:q].present?

    items = scope.offset((page - 1) * per_page).limit(per_page)
    render json: { data: items.as_json(only: %i[id first_name last_name company status email]), pagination: { page: page, per_page: per_page, total: scope.count } }
  end

  def show
    render json: { data: @lead.attributes }
  end

  def create
    lead = Lead.new(lead_params)
    if lead.save
      render json: { data: lead.attributes }, status: :created
    else
      render json: { errors: lead.errors }, status: :unprocessable_entity
    end
  end

  def update
    if @lead.update_with_lead_counters(lead_params)
      render json: { data: @lead.attributes }
    else
      render json: { errors: @lead.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    @lead.destroy
    render json: { status: 'ok' }
  end

  def promote
    account, opportunity, contact = @lead.promote(params.permit!.to_h)
    if account.errors.empty? && opportunity.errors.empty? && contact.errors.empty?
      @lead.convert
      render json: { status: 'ok', data: { account_id: account.id, opportunity_id: opportunity.id, contact_id: contact.id } }
    else
      render json: { errors: account.errors + opportunity.errors + contact.errors }, status: :unprocessable_entity
    end
  end

  def reject
    @lead.reject
    render json: { status: 'ok' }
  end

  private

  def set_lead
    @lead = Lead.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Lead not found' }, status: :not_found
  end

  def lead_params
    params.require(:lead).permit(:first_name, :last_name, :title, :company, :source, :status, :email, :alt_email, :phone, :mobile, :blog, :linkedin, :facebook, :twitter, :rating, :do_not_call, :access, :assigned_to, :background_info, :skype, :campaign_id, user_ids: [])
  end
end