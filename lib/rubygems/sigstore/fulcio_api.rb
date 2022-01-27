require "faraday_middleware"
require "openssl"

class Gem::Sigstore::FulcioApi
  def initialize(host:, oidp:)
    @host = host
    @oidp = oidp
  end

  def create(pub_key)
    response = connection.post("/api/v1/signingCert", {
      publicKey: {
        content: Base64.encode64(pub_key),
        algorithm: "ecdsa",
      },
        signedEmailAddress: Base64.encode64(oidp.proof),
    }
    )

    unless response.status == 201
      raise "Unexpected response from POST api/v1/signingCert:\n #{response.body}"
    end

    response.body
  end

  private

  attr_reader :host, :oidp

  def connection
    Faraday.new do |request|
      request.authorization :Bearer, oidp.token.to_s
      request.url_prefix = host
      request.request :json
      request.response :json, content_type: /json/
      request.adapter :net_http
    end
  end
end
