require "rails_helper"

RSpec.describe EmbedsController, type: :controller do
  describe "GET #index" do
    let(:company_droplet_uuid) { "cdr_znmpvbr5x7ndkotlhpvnyt5b5qfzvxzf" }

    context "when company exists with settings" do
      let!(:company) { create(:company, company_droplet_uuid: company_droplet_uuid, settings: { username: "test" }) }

      it "renders the index template" do
        get :index, params: { company_droplet_uuid: company_droplet_uuid }
        expect(response).to render_template(:index)
      end
    end

    context "when company exists without settings" do
      let!(:company) { create(:company, company_droplet_uuid: company_droplet_uuid, settings: nil) }

      it "renders the initialize template" do
        get :index, params: { company_droplet_uuid: company_droplet_uuid }
        expect(response).to render_template(:initialize)
      end
    end

    context "when company does not exist" do
      it "renders the initialize template" do
        get :index, params: { company_droplet_uuid: company_droplet_uuid }
        expect(response).to render_template(:initialize)
      end
    end
  end
end
