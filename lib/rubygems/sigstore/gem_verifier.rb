require "rubygems/sigstore/rekord_entry"

class Gem::Sigstore::GemVerifier
  include Gem::UserInteraction

  Data = Struct.new(:digest, :signature, :raw)

  def initialize(gemfile:, config:)
    @gemfile = gemfile
    @config = config
  end

  def run
    rekor_api = Gem::Sigstore::RekorApi.new(host: config.rekor_host)
    entries = rekor_api.where(data_digest: gemfile.digest) # TODO: we should only pass on the entries where body.kind == "rekord"
    rekord_entries = entries.map { |entry| Gem::Sigstore::RekordEntry.new(entry.values.first) }
    rekords = rekord_entries.select { |entry| valid_signature?(entry, gemfile) }

    if rekords.empty?
      say "No valid signatures found for digest #{gemfile.digest}"
    else
      say ":noice:"
      print_signers(rekords)
    end
  end

  private

  attr_reader :gemfile, :config

  def valid_signature?(rekord_entry, gemfile)
    public_key = rekord_entry.signer_public_key
    digest = gemfile.digest
    signature = rekord_entry.signature
    content = gemfile.content

    public_key.verify(digest, signature, content)
  end

  def print_signers(rekords)
    maintainers, others = rekords.map(&:signer_email).uniq.partition do |email|
      gemfile.maintainer?(email)
    end

    unless maintainers.empty?
      say "Signed by maintainer#{maintainers.size == 1 ? '' : 's'}: #{email_list(maintainers)}"
    end

    unless others.empty?
      say "Signed by non-maintainer#{others.size == 1 ? '' : 's'}: #{email_list(others)}"
    end
  end

  def email_list(emails)
    return emails.first if emails.size == 1

    emails[0...-1].join(", ") + " and #{emails.last}"
  end
end
