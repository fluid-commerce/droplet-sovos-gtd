class SovosClient
  class ApiError < StandardError; end

  attr_reader :company, :cart_payload
  include HTTParty
  base_uri "https://gtduat.sovos.com/Twe/api/rest/"
  format :json

  def initialize(company, cart_payload)
    @company = company
    @cart_payload = cart_payload
  end

  def headers
    auth_header = gtd_auth_headers
    {
      "Authorization" => auth_header["auth_header"],
      "Content-Type" => "application/json",
      "Date" => auth_header["timestamp"],
    }
  end

  def calculate_tax
    response = self.class.post("/calculateTax", headers: headers, body: payload.to_json)
    if response.code == 200
      response.parsed_response
    else
      # since we do not have api credentials right now, we are returning a dummy response instead of returning the error
      # dummy_response
      raise ApiError, "Failed to calculate tax: #{response.code} #{response.body}"
    end
  end

  # TODO: remove this once we have api credentials
  def dummy_response
    {
      "txAmt" => 100,
      "txRate" => 0.1,
      "txType" => "Sales Tax",
      "lnRslt" => [
        {
          "lnId" => "1",
          "txAmt" => 100,
          "grossAmt" => 1000,
          "txRate" => 0.1,
        },
      ],
    }
  end


  def payload
    ship_to = cart_payload["addresses"]["ship_to"]
    {
      username: company.settings["username"],
      password: company.settings["password"],
      isAudit: false,
      currn: cart_payload["currency_code"],
      grossAmt: cart_payload["total"],
      shipTo: {
        sTStNameNum: "#{ship_to["address1"]} #{ship_to["address2"]}",
        sTCity: ship_to["city"],
        sTStateProv: ship_to["state"],
        sTPstlCd: ship_to["zip"],
        sTCountry: ship_to["country"],
      },
      docDt: Time.now.strftime("%Y-%m-%d"),
      lines: cart_payload["lines"].map { |line|
        {
          debCredIndr: "1",
          grossAmt: line["total_price"],
          lnItmId: line["id"],
          qnty: line["quantity"],
          trnTp: "1",
          orgCd: "DefaultOrg",
        }
      },
    }
  end

  def gtd_auth_headers
    GtdAuthService.new(company).generate_auth_header
  end
end
