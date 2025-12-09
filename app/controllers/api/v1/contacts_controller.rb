class Api::V1::ContactsController < ApplicationController
  before_action :set_contact, only: [:show, :update, :destroy]

  def index
    page     = params[:page].to_i > 0 ? params[:page].to_i : 1
    per_page = params[:per_page].to_i > 0 ? params[:per_page].to_i : 20
    scope    = Contact.order(id: :desc)
    scope    = scope.text_search(params[:query]) if params[:query].present?
    scope    = scope.merge(Contact.ransack(params[:q]).result) if params[:q].present?

    items = scope.offset((page - 1) * per_page).limit(per_page)
    render json: { data: items.as_json(only: %i[id first_name last_name email phone]), pagination: { page: page, per_page: per_page, total: scope.count } }
  end

  def show
    render json: { data: @contact.attributes }
  end

  def create
    contact = Contact.new(contact_params)
    if contact.save_with_account_and_permissions(params.permit!.to_h)
      render json: { data: contact.attributes }, status: :created
    else
      render json: { errors: contact.errors }, status: :unprocessable_entity
    end
  end

  def update
    if @contact.update_with_account_and_permissions(params.permit!.to_h)
      render json: { data: @contact.attributes }
    else
      render json: { errors: @contact.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    @contact.destroy
    render json: { status: 'ok' }
  end

  private

  def set_contact
    @contact = Contact.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Contact not found' }, status: :not_found
  end

  def contact_params
    params.require(:contact).permit(:first_name, :last_name, :title, :department, :source, :email, :alt_email, :phone, :mobile, :fax, :blog, :linkedin, :facebook, :twitter, :born_on, :do_not_call, :access, :assigned_to, :background_info, :skype, :lead_id, :reports_to, :user_id)
  end
end