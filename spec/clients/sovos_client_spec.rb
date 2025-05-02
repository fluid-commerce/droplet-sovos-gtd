require "rails_helper"

RSpec.describe SovosClient do
  include ActiveSupport::Testing::TimeHelpers

  let(:company) { create(:company, :with_sovos_settings) }
  let(:cart_payload) do
    {
      "currency_code" => "USD",
      "total" => 100.00,
      "addresses" => {
        "ship_to" => {
          "address1" => "123 Main St",
          "address2" => "Apt 4B",
          "city" => "Test City",
          "state" => "TS",
          "zip" => "12345",
          "country" => "US",
        },
      },
      "lines" => [
        {
          "id" => "1",
          "total_price" => 100.00,
          "quantity" => 1,
          "product" => {
            "name" => "Test Product",
            "code" => "TP001",
          },
        },
      ],
    }
  end
  let(:client) { described_class.new(company, cart_payload) }
  let(:auth_service) { instance_double(GtdAuthService) }
  let(:auth_response) do
    {
      timestamp: "2024-01-01T12:00:00Z",
      auth_header: "TAX test_user:test_digest",
    }
  end

  before do
    allow(GtdAuthService).to receive(:new).with(company).and_return(auth_service)
    allow(auth_service).to receive(:generate_auth_header).and_return(auth_response)
  end

  describe "#calculate_tax" do
    let(:expected_response) do
      {
        "txAmt" => 7.50,
        "txDt" => "2024-01-01",
        "txLoc" => {
          "txCty" => "Test City",
          "txSt" => "TS",
          "txZip" => "12345",
        },
      }
    end

    let(:auth_headers) do
      {
        "auth_header" => "TAX test_user:test_digest",
        "timestamp" => "2024-01-01T12:00:00Z",
      }
    end

    before do
      travel_to Time.new(2025, 4, 30)
      allow_any_instance_of(described_class).to receive(:gtd_auth_headers).and_return(auth_headers)

      stub_request(:post, "https://gtduat.sovos.com/Twe/api/rest/calculateTax")
        .with(
          body: payload_json,
          headers: {
            "Authorization" => auth_headers["auth_header"],
            "Content-Type" => "application/json",
            "Date" => auth_headers["timestamp"],
            "Accept" => "*/*",
            "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
            "User-Agent" => "Ruby",
          }
        )
        .to_return(
          status: 200,
          body: expected_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    let(:payload_json) do
      {
        username: "test_user",
        password: "test_pass",
        isAudit: false,
        currn: "USD",
        grossAmt: 100.0,
        shipTo: {
          sTStNameNum: "123 Main St Apt 4B",
          sTCity: "Test City",
          sTStateProv: "TS",
          sTPstlCd: "12345",
          sTCountry: "US",
        },
        docDt: "2025-04-30",
        lines: [
          {
            debCredIndr: "1",
            grossAmt: 100.0,
            lnItmId: "1",
            qnty: 1,
            trnTp: "1",
            orgCd: "DefaultOrg",
          },
        ],
      }.to_json
    end

    after do
      travel_back
    end

    it "makes a request to calculate tax" do
      response = client.calculate_tax
      expect(response).to eq(expected_response)
    end

    context "when the request fails" do
      before do
        stub_request(:post, "https://gtduat.sovos.com/Twe/api/rest/calculateTax")
          .to_return(status: 500, body: "Internal Server Error")
      end

      it "raises an error" do
        expect { client.calculate_tax }.to raise_error(SovosClient::ApiError)
      end
    end
  end
end
