require "rails_helper"

RSpec.describe SovosController, type: :controller do
  let(:company_droplet_uuid) { "cdr_znmpvbr5x7ndkotlhpvnyt5b5qfzvxzf" }
  let(:valid_settings) do
    {
      username: "test_user",
      password: "test_pass",
      hmac_key: "test_key",
    }
  end

  describe "POST #update_settings" do
    context "with valid parameters" do
      let!(:company) { create(:company, company_droplet_uuid: company_droplet_uuid) }
      let(:params) { valid_settings.merge(company_droplet_uuid: company_droplet_uuid) }

      it "updates company settings and redirects" do
        post :update_settings, params: params
        expect(company.reload.settings).to include(
          "username" => "test_user",
          "password" => "test_pass",
          "hmac_key" => "test_key"
        )
        expect(response).to redirect_to(embed_path(company_droplet_uuid: company_droplet_uuid))
        expect(flash[:notice]).to eq("Settings updated successfully")
      end
    end

    context "with invalid parameters" do
      it "returns bad request" do
        post :update_settings, params: { company_droplet_uuid: company_droplet_uuid }
        expect(response).to have_http_status(:bad_request)
      end
    end

    context "when company not found" do
      let(:params) { valid_settings.merge(company_droplet_uuid: "invalid") }

      it "returns not found" do
        post :update_settings, params: params
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "POST #calculate_tax" do
    let(:valid_cart) do
      {
        cart_token: "test_token",
        lines: [
          {
            id: "1",
            amount: 100,
            quantity: 1,
          },
        ],
      }
    end

    context "with valid parameters" do
      let!(:company) { create(:company, company_droplet_uuid: company_droplet_uuid, settings: valid_settings) }
      let(:sovos_response) { { "txAmt" => 10 } }

      before do
        allow_any_instance_of(SovosClient).to receive(:calculate_tax).and_return(sovos_response)
        allow_any_instance_of(FluidCartService).to receive(:update_cart).and_return(true)
      end

      it "calculates tax and updates cart" do
        post :calculate_tax, params: {
          company_droplet_uuid: company_droplet_uuid,
          payload: { cart: valid_cart },
        }
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to include(
          "success" => true,
          "total_tax" => 10
        )
      end
    end

    context "with invalid cart parameters" do
      it "returns bad request" do
        post :calculate_tax, params: {
          company_droplet_uuid: company_droplet_uuid,
          payload: { cart: { lines: [] } },
        }
        expect(response).to have_http_status(:bad_request)
      end
    end

    context "when company not found" do
      it "returns not found" do
        post :calculate_tax, params: {
          company_droplet_uuid: "invalid",
          payload: { cart: valid_cart },
        }
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when tax calculation fails" do
      let!(:company) { create(:company, company_droplet_uuid: company_droplet_uuid, settings: valid_settings) }

      before do
        allow_any_instance_of(SovosClient).to receive(:calculate_tax).and_raise("API Error")
      end

      it "returns error response" do
        post :calculate_tax, params: {
          company_droplet_uuid: company_droplet_uuid,
          payload: { cart: valid_cart },
        }
        expect(response).to have_http_status(:internal_server_error)
        expect(JSON.parse(response.body)).to include(
          "success" => false,
          "error" => "API Error"
        )
      end
    end
  end
end
