class SovosController < ApplicationController
  before_action :set_company, only: %i[update_settings calculate_tax]
  skip_before_action :verify_authenticity_token

  def update_settings
    return bad_request_response unless valid_params?

    return not_found_response unless @company.present?

    @company.settings = sanitized_settings

    if @company.save
      redirect_to(
        embed_path(company_droplet_uuid: @company.company_droplet_uuid),
        notice: "Settings updated successfully"
      )
    else
      redirect_to(
        embed_path(company_droplet_uuid: @company.company_droplet_uuid),
        error: "Failed to update settings"
      )
    end
  end

  def calculate_tax
    return bad_request_response unless valid_cart_params?

    return not_found_response unless @company.present?

    cart_token = cart_payload["cart_token"]
    sovos_client = SovosClient.new(@company, cart_payload)
    response = sovos_client.calculate_tax
    update_fluid_cart(cart_token, response)
    render json: { success: true, total_tax: response["txAmt"] }, status: :ok
  rescue => e
    render json: { success: false, error: e.message }, status: :internal_server_error
  end


private

  def update_fluid_cart(cart_token, response)
    fluid_cart = FluidCartService.new(cart_token, response)
    fluid_cart.update_cart
  end

  def cart_payload
    params.dig(:payload, :cart)
  end

  def valid_params?
    required_params = %i[username password hmac_key company_droplet_uuid]
    required_params.all? { |param| params[param].present? }
  end

  def valid_cart_params?
    cart_payload = params.dig(:payload, :cart)
    return false if cart_payload.blank?

    lines = cart_payload["lines"]
    return false if lines.blank? || !lines.is_a?(Array)

    lines.all? do |line|
      line["amount"].present? &&
      line["id"].present? &&
      line["quantity"].present?
    end
  end

  def sanitized_settings
    {
      username: params[:username].to_s.strip,
      password: params[:password].to_s.strip,
      hmac_key: params[:hmac_key].to_s.strip,
    }
  end

  def bad_request_response
    render json: { error: "Invalid request parameters" }, status: :bad_request
  end

  def not_found_response
    render json: { error: "Company not Found" }, status: :not_found
  end

  def set_company
    @company = Company.find_by(company_droplet_uuid: params[:company_droplet_uuid])
  end
end
