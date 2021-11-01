require "rubygems/sigstore/rekord_entry"

class Gem::Sigstore::GemVerifier
  Data = Struct.new(:digest, :signature, :raw)

  def initialize(gemfile:, config:, io: $stdout)
    @gemfile = gemfile
    @config = config
    @io = io
  end

  def run
    rekor_api = Gem::Sigstore::RekorApi.new(host: config.rekor_host)
    entries = rekor_api.where(data_digest: gemfile.digest)
    rekord_entries = entries.map { |entry| Gem::Sigstore::RekordEntry.new(entry.values.first) }
    rekord = rekord_entries.find { |entry| entry.valid_signature?(gemfile.digest, gemfile.content) }

    if rekord
      io.puts ":noice:, signed by #{rekord.signer_email}"
    else
      io.puts "not :noice: thxkbye"
    end
  end

  private

  attr_reader :gemfile, :config, :io
end
