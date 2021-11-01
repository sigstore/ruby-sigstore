class Gem::Sigstore::CertProvider
  def initialize(config:, pkey:)
    @config = config
    @pkey = pkey
  end

  def run
    proof, access_token = Gem::Sigstore::OpenID.new(pkey.private_key).get_token
    fulcio_api = Gem::Sigstore::FulcioApi.new(token: access_token, host: config.fulcio_host)
    fulcio_api.create(proof, pkey.public_key.to_der)
  end

  private

  attr_reader :config, :pkey
end
