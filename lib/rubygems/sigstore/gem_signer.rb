require "rubygems/user_interaction"
require "rubygems/sigstore/crypto"
require "rubygems/sigstore/cert_provider"
require "rubygems/sigstore/file_signer"
require "rubygems/sigstore/rekor"

class Gem::Sigstore::GemSigner
  include Gem::UserInteraction

  Data = Struct.new(:digest, :signature, :raw)

  def initialize(gemfile:, config:)
    @gemfile = gemfile
    @config = config
  end

  def run
    pkey = Gem::Sigstore::PKey.new
    cert = Gem::Sigstore::CertProvider.new(config: config, pkey: pkey).run

    yield if block_given?

    say "Fulcio certificate chain"
    say cert
    say
    say "Sending gem digest, signature & certificate chain to transparency log."

    Gem::Sigstore::FileSigner.new(
      file: gemfile,
      pkey: pkey,
      transparency_log: Gem::Sigstore::Rekor::Api.new(host: config.rekor_host),
      cert: cert
    ).run
  end

  private

  attr_reader :gemfile, :config
end
