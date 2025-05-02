require "rails_helper"

RSpec.describe GtdAuthService do
  let(:username) { "test_user" }
  let(:password) { "test_pass" }
  let(:hmac_key) { "test_key" }
  let(:settings) do
    {
      "username" => username,
      "password" => password,
      "hmac_key" => hmac_key,
    }
  end
  let(:company) { create(:company, settings: settings) }
  let(:service) { described_class.new(company) }

  describe "#generate_auth_header" do
    let(:fixed_time) { Time.new(2024, 1, 1, 12, 0, 0, "+00:00") }
    let(:expected_timestamp) { "2024-01-01T12:00:00Z" }

    before do
      allow(Time).to receive(:now).and_return(fixed_time)
    end

    context "with valid credentials" do
      it "generates the correct authorization header" do
        result = service.generate_auth_header

        expect(result).to be_a(Hash)
        expect(result[:timestamp]).to eq(expected_timestamp)
        expect(result[:auth_header]).to start_with("TAX #{username}:")
      end

      it "includes a Base64 encoded HMAC digest" do
        result = service.generate_auth_header
        digest = result[:auth_header].split(":").last

        expect { Base64.strict_decode64(digest) }.not_to raise_error
      end
    end

    context "with missing credentials" do
      let(:settings) { {} }

      it "returns a header with empty values" do
        result = service.generate_auth_header

        expect(result).to be_a(Hash)
        expect(result[:timestamp]).to eq(expected_timestamp)
        expect(result[:auth_header]).to eq("TAX :")
      end
    end

    context "with nil settings" do
      let(:settings) { nil }

      it "returns a header with empty values" do
        result = service.generate_auth_header

        expect(result).to be_a(Hash)
        expect(result[:timestamp]).to eq(expected_timestamp)
        expect(result[:auth_header]).to eq("TAX :")
      end
    end

    context "with custom request suffix" do
      let(:custom_suffix) { "custom/path" }

      it "uses the custom suffix in signature generation" do
        result = service.generate_auth_header(custom_suffix)

        plain_string = "POSTapplication/json#{expected_timestamp}/Twe/api/rest/#{custom_suffix}#{username}#{password}"
        expected_digest = Base64.strict_encode64(
          OpenSSL::HMAC.digest("sha1", hmac_key, plain_string)
        )
        expected_auth_header = "TAX #{username}:#{expected_digest}"

        expect(result[:auth_header]).to eq(expected_auth_header)
      end
    end
  end
end
