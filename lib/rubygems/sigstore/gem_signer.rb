require "rubygems/user_interaction"
require "rubygems/sigstore/pkey"
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
    cert = cert_provider.run

    yield if block_given?

    say "Fulcio certificate chain"
    say cert
    say
    say "Sending gem digest, signature & certificate chain to transparency log."

    gemfile_signer(cert).run
  end

  private

  attr_reader :gemfile, :config

  def cert_provider
    Gem::Sigstore::CertProvider.new(config: config, pkey: pkey, oidp: oidp)
  end

  def pkey
    @pkey ||= Gem::Sigstore::PKey.new
  end

  def oidp
    @oidp ||= Gem::Sigstore::OpenID::Dynamic.new(pkey.private_key)
  end

  def gemfile_signer(cert)
    Gem::Sigstore::FileSigner.new(file: gemfile, pkey: pkey, transparency_log: rekor_api, cert: cert)
  end

  def rekor_api
    Gem::Sigstore::Rekor::Api.new(host: config.rekor_host)
  end
end
