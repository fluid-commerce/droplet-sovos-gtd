class FluidCartService
  def initialize(cart_token, payload)
    @cart_token = cart_token
    @payload = payload
  end

  def update_cart
    FluidClient.new.put("/api/carts/#{@cart_token}", body: formatted_payload)
  end

private

  def formatted_payload
    # TODO: currently adding the tax_total only to the payload
    # need to add more details once more info is available
    {
      tax_total: @payload["txAmt"],
    }
  end
end
