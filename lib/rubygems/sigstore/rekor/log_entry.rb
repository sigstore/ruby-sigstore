class Gem::Sigstore::Rekor::LogEntry
  def self.from(entry_response)
    uuid = entry_response.keys.first
    entry = entry_response[uuid]
    body = encoded_body_to_hash(entry["body"])

    case body["kind"]
    when "rekord"
      Gem::Sigstore::Rekor::Rekord.new(uuid, entry)
    else
      new(uuid, entry)
    end
  end

  def self.encoded_body_to_hash(body)
    JSON.parse(Base64.decode64(body))
  end

  attr_reader :uuid, :attestation, :body, :integrated_time

  def initialize(uuid, entry)
    @uuid = uuid
    @attestation = entry["attestation"]
    @body = Gem::Sigstore::Rekor::LogEntry.encoded_body_to_hash(entry["body"])
    @integrated_time = entry["integratedTime"]
  end

  def kind
    body["kind"]&.to_sym || :log_entry
  end
end
