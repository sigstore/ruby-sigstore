require "faraday_middleware"
require "openssl"

class Gem::Sigstore::FulcioApi
  def initialize(host:, token:)
    @host = host
    @token = token.to_s
  end

  def create(proof, pub_key)
    connection.post("/api/v1/signingCert", {
      publicKey: {
        content: Base64.encode64(pub_key),
        algorithm: "ecdsa"
      },
      signedEmailAddress: proof
    }).body
  end

  private

  def connection
    Faraday.new do |request|
      request.authorization :Bearer, @token
      request.url_prefix = @host
      request.request :json
      request.response :json, content_type: /json/
      request.adapter :net_http
    end
  end
end
