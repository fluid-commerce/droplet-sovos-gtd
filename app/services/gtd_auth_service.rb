require "openssl"
require "base64"

class GtdAuthService
  def initialize(company)
    settings = company.settings || {}
    @username = settings["username"].to_s
    @password = settings["password"].to_s
    @hmac_key = settings["hmac_key"].to_s
  end

  def generate_auth_header(request_suffix = "")
    timestamp = Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ")
    digest = generate_hmac_digest(timestamp, request_suffix)

    {
      timestamp: timestamp,
      auth_header: "TAX #{@username}:#{digest}",
    }
  end

private

  def generate_hmac_digest(timestamp, request_suffix)
    return "" if @hmac_key.empty?

    data = "POSTapplication/json#{timestamp}/Twe/api/rest/#{request_suffix}#{@username}#{@password}"
    digest = OpenSSL::HMAC.digest("sha1", @hmac_key, data)
    Base64.strict_encode64(digest)
  end
end
