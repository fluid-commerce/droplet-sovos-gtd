require "rails_helper"

RSpec.describe FluidCartService do
  let(:cart_token) { "test_cart_token" }
  let(:tax_payload) { { "txAmt" => 10.50 } }
  let(:service) { described_class.new(cart_token, tax_payload) }

  describe "#update_cart" do
    let(:fluid_client) { instance_double(FluidClient) }
    let(:expected_payload) { { tax_total: 10.50 } }

    before do
      allow(FluidClient).to receive(:new).and_return(fluid_client)
      allow(fluid_client).to receive(:put).with(
        "/api/carts/#{cart_token}",
        body: expected_payload
      ).and_return(true)
    end

    it "updates the cart with tax information" do
      expect(service.update_cart).to be true
      expect(fluid_client).to have_received(:put).with(
        "/api/carts/#{cart_token}",
        body: expected_payload
      )
    end

    context "when the API call fails" do
      before do
        allow(fluid_client).to receive(:put).and_raise("API Error")
      end

      it "raises the error" do
        expect { service.update_cart }.to raise_error("API Error")
      end
    end
  end
end
