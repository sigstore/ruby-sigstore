class Gem::Sigstore::OpenID::Static
  def initialize(priv_key, token)
    @priv_key = priv_key
    @unparsed_token = token
  end

  # https://www.youtube.com/watch?v=ZsgA77j5LyY
  def proof
    @proof ||= create_proof
  end

  def token
    parse_token unless defined?(@token)
    @token ||= @unparsed_token.to_s
  end

  private

  def create_proof
    pkey.sign_proof(subject)
  end

  def pkey
    @pkey ||= Gem::Sigstore::PKey.new(private_key: @priv_key)
  end

  def parsed_token
    @parsed_token ||= parse_token
  end

  def parse_token
    begin
      decoded_access_token = JSON::JWT.decode(@unparsed_token.to_s, public_keys)
      JSON.parse(decoded_access_token.to_json)
    rescue JSON::JWS::VerificationFailed => e
      abort 'JWT Verification Failed: ' + e.to_s
    end
  end

  def subject
    return email if email

    if parsed_token["subject"].empty?
      abort 'No subject found in claims'
    end

    parsed_token["subject"]
  end

  def email
    return unless parsed_token["email"]

    # ensure that the OIDC provider has verified the email address
    # note: this may have happened some time in the past
    unless parsed_token["email_verified"]
      abort 'Email address in OIDC token was not verified by identity provider'
    end

    parsed_token["email"]
  end

  def public_keys
    @public_keys ||= oidc_discovery.jwks
  end

  def oidc_discovery
    OpenIDConnect::Discovery::Provider::Config.discover! config.oidc_issuer
  end

  def config
    Gem::Sigstore::Config.read
  end
end
