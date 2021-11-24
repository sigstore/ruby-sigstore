class Gem::Sigstore::CertProvider
  def initialize(config:, pkey:, oidp:)
    @config = config
    @pkey = pkey
    @oidp = oidp
  end

  def run
    fulcio_api.create(pkey.public_key.to_der)
  end

  private

  attr_reader :config, :pkey, :oidp

  def fulcio_api
    Gem::Sigstore::FulcioApi.new(oidp: oidp, host: config.fulcio_host)
  end
end
