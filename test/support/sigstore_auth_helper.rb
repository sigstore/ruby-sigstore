module SigstoreAuthHelper
  include UrlHelper

  SIGSTORE_OAUTH2_BASE_URL = 'https://oauth2.sigstore.dev/'

  def sigstore_auth_url(*path, **kwargs)
    url_regex(SIGSTORE_OAUTH2_BASE_URL, 'auth', path, **kwargs)
  end

  # OpenID config

  def sigstore_auth_openid_config_url
    sigstore_auth_url('.well-known', 'openid-configuration')
  end

  def stub_sigstore_auth_get_openid_config(returning: {})
    stub_request(:get, sigstore_auth_openid_config_url)
      .to_return_json(build_sigstore_auth_openid_config(returning))
  end

  def build_sigstore_auth_openid_config(options)
    {
      issuer: "https://oauth2.sigstore.dev/auth",
      authorization_endpoint: "https://oauth2.sigstore.dev/auth/auth",
      token_endpoint: "https://oauth2.sigstore.dev/auth/token",
      jwks_uri: "https://oauth2.sigstore.dev/auth/keys",
      userinfo_endpoint: "https://oauth2.sigstore.dev/auth/userinfo",
      device_authorization_endpoint: "https://oauth2.sigstore.dev/auth/device/code",
      grant_types_supported: ["authorization_code", "refresh_token", "urn:ietf:params:oauth:grant-type:device_code"],
      response_types_supported: ["code"],
      subject_types_supported: ["public"],
      id_token_signing_alg_values_supported: ["RS256"],
      code_challenge_methods_supported: ["S256", "plain"],
      scopes_supported: ["openid", "email", "groups", "profile", "offline_access"],
      token_endpoint_auth_methods_supported: ["client_secret_basic", "client_secret_post"],
      claims_supported: ["iss", "sub", "aud", "iat", "exp", "email", "email_verified", "locale", "name", "preferred_username", "at_hash"]
    }.merge(options)
  end

  # Access token

  def sigstore_auth_token_url
    sigstore_auth_url('token')
  end

  def stub_sigstore_auth_create_token(headers: {}, body: {}, returning: {})
    stub_request(:post, sigstore_auth_url('token'))
      .with(
        headers: {
            authorization: 'Basic c2lnc3RvcmU6', #u: sigstore, no password.  From settings.yml
            content_type: 'application/x-www-form-urlencoded',
        }.merge(headers),
        body: hash_including(
          {
            grant_type: "authorization_code",
            code: "DUMMY",
            code_verifier: /[a-z0-9]+/,
          }.merge(body)
        ),
      )
      .to_return_json(build_sigstore_auth_access_token(returning))
  end

  def build_sigstore_auth_access_token(options)
    {
      access_token: access_token,
      token_type: "bearer",
      expires_in: 59,
      id_token: "",
    }.merge(options)
  end

  # JSON web keys

  def sigstore_auth_keys_url
    sigstore_auth_url('keys')
  end

  def stub_sigstore_auth_get_keys(returning: {})
    stub_request(:get, sigstore_auth_keys_url)
      .to_return_json(build_sigstore_auth_keys(returning))
  end

  def build_sigstore_auth_keys(options)
    {
      keys: [access_token_jwk]
    }.merge(options)
  end

  def access_token
    @access_token ||= begin
      claim = {
        iss: "https://oauth2.sigstore.dev/auth",
        aud: "sigstore",
        exp: 1.minute.from_now,
        iat: Time.now,
        email: "someone@example.org",
        email_verified: true,
      }
      jws = JSON::JWT.new(claim).sign(access_token_jwk, :RS256)
      jws.to_s
    end
  end

  def access_token_jwk
    @access_token_jwk ||= JSON::JWK.new(access_token_pkey, kid: "dummy_kid", use: "sig")
  end

  def access_token_pkey
    @access_token_pkey ||= OpenSSL::PKey::RSA.generate(1024)
  end
end
