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
    rekords = rekord_entries.select { |entry| valid_signature?(entry, gemfile) }

    if rekords.empty?
      io.puts "not :noice: thxkbye"
    else
      io.puts ":noice:"
      print_signers(rekords)
    end
  end

  private

  attr_reader :gemfile, :config, :io

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
      io.puts "Signed by maintainer#{maintainers.size == 1 ? '' : 's'}: #{email_list(maintainers)}"
    end

    unless others.empty?
      io.puts "Signed by non-maintainer#{others.size == 1 ? '' : 's'}: #{email_list(others)}"
    end
  end

  def email_list(emails)
    return emails.first if emails.size == 1

    emails[...-1].join(", ") + " and #{emails.last}"
  end
end
