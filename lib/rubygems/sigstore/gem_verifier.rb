require "rubygems/user_interaction"
require "rubygems/sigstore/rekor"

class Gem::Sigstore::GemVerifier
  include Gem::UserInteraction

  Data = Struct.new(:digest, :signature, :raw)

  def initialize(gemfile:, config:)
    @gemfile = gemfile
    @config = config
  end

  def run
    rekor_api = Gem::Sigstore::Rekor::Api.new(host: config.rekor_host)
    log_entries = rekor_api.where(data_digest: gemfile.digest)
    rekords = log_entries.select { |entry| entry.kind == :rekord }

    valid_signature_rekords = rekords.select { |rekord| valid_signature?(rekord, gemfile) }

    if valid_signature_rekords.empty?
      say "No valid signatures found for digest #{gemfile.digest}"
    else
      say ":noice:"
      print_signers(valid_signature_rekords)
    end
  end

  private

  attr_reader :gemfile, :config

  def valid_signature?(rekord, gemfile)
    public_key = rekord.signer_public_key
    digest = gemfile.digest
    signature = rekord.signature
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
