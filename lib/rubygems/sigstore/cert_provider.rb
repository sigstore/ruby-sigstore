class Gem::Sigstore::CertProvider
  def initialize(config:, pkey:)
    @config = config
    @pkey = pkey
  end

  def run
    oidp = Gem::Sigstore::OpenID::Dynamic.new(pkey.private_key)
    fulcio_api = Gem::Sigstore::FulcioApi.new(oidp: oidp, host: config.fulcio_host)
    fulcio_api.create(pkey.public_key.to_der)
  end

  private

  attr_reader :config, :pkey
end
