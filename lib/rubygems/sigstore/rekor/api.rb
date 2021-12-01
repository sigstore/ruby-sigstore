require "faraday_middleware"
require "openssl"
require "rubygems/sigstore/rekor/log_entry"

class Gem::Sigstore::Rekor::Api
  def initialize(host:)
    @host = host
  end

  def create(cert_chain, data)
    connection.post("/api/v1/log/entries",
      {
        kind: "rekord",
        apiVersion: "0.0.1",
        spec: {
          signature: {
            format: "x509",
            content: Base64.encode64(data.signature),
            publicKey: {
              content: Base64.encode64(cert_chain),
            },
          },
          data: {
            content: Base64.encode64(data.raw),
            hash: {
              algorithm: "sha256",
              value: data.digest,
            },
          },
        },
      }).body
  end

  def where(data_digest:)
    retrieve_response = connection.post("/api/v1/index/retrieve",
      {
        hash: "sha256:#{data_digest}",
      }
    )

    unless retrieve_response.status == 200
      raise "Unexpected response from POST /api/v1/index/retrieve:\n #{retrieve_response}"
    end

    retrieve_response = connection.post("api/v1/log/entries/retrieve", entryUUIDs: retrieve_response.body)

    unless retrieve_response.status == 200
      raise "Unexpected response from POST api/v1/log/entries/retrieve:\n #{entry_response}"
    end

    retrieve_response.body.reduce(:merge).map do |uuid, entry|
      Gem::Sigstore::Rekor::LogEntry.from(uuid, entry)
    end
  end

  private

  def connection
    # rekor uses a self signed certificate which failes the ssl check
    Faraday.new(ssl: { verify: false }) do |request|
      # request.authorization :Bearer, id_token.to_s
      request.url_prefix = @host
      request.request :json
      request.response :json, content_type: /json/
      request.adapter :net_http
    end
  end
end
