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
        kind: "hashedrekord",
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
            hash: {
              algorithm: "sha256",
              value: data.digest,
            },
          },
        },
      }).body
  end

  def where(data_digest:)
    log_entry_uuids = find_log_entry_uuids_by_digest(data_digest)

    return [] if log_entry_uuids.empty?

    find_log_entries_by_uuid(log_entry_uuids).reduce({}, :merge).map do |uuid, entry|
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

  def find_log_entry_uuids_by_digest(digest)
    index_response = connection.post("/api/v1/index/retrieve",
      {
        hash: "sha256:#{digest}",
      }
    )

    unless index_response.status == 200
      raise "Unexpected response from POST /api/v1/index/retrieve:\n #{index_response}"
    end

    index_response.body
  end

  def find_log_entries_by_uuid(uuids)
    log_entries_response = connection.post("api/v1/log/entries/retrieve", entryUUIDs: uuids)

    unless log_entries_response.status == 200
      raise "Unexpected response from POST api/v1/log/entries/retrieve:\n #{log_entries_response}"
    end

    log_entries_response.body
  end
end
