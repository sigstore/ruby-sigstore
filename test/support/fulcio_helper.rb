module FulcioHelper
  include UrlHelper
  include SigstoreAuthHelper

  FULCIO_BASE_URL = 'https://fulcio.sigstore.dev'.freeze
  FULCIO_FAKE_CA_BASE_URL = 'http://ca.example.org.org'.freeze

  def fulcio_api_url(*path, **kwargs)
    url_regex(FULCIO_BASE_URL, 'api', 'v1', path, **kwargs)
  end

  def fulcio_signing_cert_url
    fulcio_api_url('signingCert')
  end

  def stub_fulcio_create_signing_cert(headers: {}, body: {}, returning: {})
    stub_request(:post, fulcio_signing_cert_url)
      .with(
        headers: {
          accept: '*/*',
          authorization: "Bearer #{access_token}",
          content_type: 'application/json',
        }.merge(headers),
        body: hash_including(
          {
            publicKey: hash_including({
              content: BASE64_ENCODED_PATTERN,
              algorithm: "ecdsa",
            }),
            signedEmailAddress: BASE64_ENCODED_PATTERN,
          }.merge(body)
        ),
      )
      .to_return do |request|
        {
          status: 201,
          headers: {},
          body: build_fulcio_cert_chain(signing_cert_key(request)).join,
        }.merge(returning)
      end
  end

  def build_fulcio_cert_chain(public_signing_key, signing_cert_options: {})
    ef = OpenSSL::X509::ExtensionFactory.new

    issuing_key = OpenSSL::PKey::RSA.new(1024)
    issuer_subject = "/O=sigstore.dev/CN=sigstore"

    issuing_cert = OpenSSL::X509::Certificate.new
    issuing_cert.subject = issuing_cert.issuer = OpenSSL::X509::Name.parse(issuer_subject)
    issuing_cert.not_before = Time.now
    issuing_cert.not_after = Time.now + 10.years
    issuing_cert.public_key = issuing_key.public_key
    issuing_cert.serial = 0x0
    issuing_cert.version = 2
    issuing_cert.add_extension(ef.create_extension("basicConstraints","CA:FALSE",true))
    issuing_cert.add_extension(ef.create_extension("keyUsage","keyCertSign, cRLSign", true))

    issuing_cert.sign(issuing_key, OpenSSL::Digest.new("SHA256"))

    options = default_signing_cert_options.merge(signing_cert_options)

    signing_cert = OpenSSL::X509::Certificate.new
    signing_cert.issuer = OpenSSL::X509::Name.parse(issuer_subject)
    signing_cert.not_before = options[:not_before]
    signing_cert.not_after = options[:not_before] + 10.minutes
    signing_cert.public_key = public_signing_key
    signing_cert.serial = 0x0
    signing_cert.version = 2
    signing_cert.add_extension(ef.create_extension("basicConstraints","CA:TRUE",true))
    signing_cert.add_extension(ef.create_extension("keyUsage","digitalSignature", true))
    signing_cert.add_extension(ef.create_extension("extendedKeyUsage","codeSigning", true))
    signing_cert.add_extension(ef.create_extension("authorityInfoAccess","caIssuers;URI:#{FULCIO_FAKE_CA_BASE_URL}/ca.crt", true))
    signing_cert.add_extension(ef.create_extension("subjectAltName","email:#{options[:email]}", true))
    signing_cert.sign(issuing_key, OpenSSL::Digest.new("SHA256"))

    [issuing_cert, signing_cert].map(&:to_pem)
  end

  def default_signing_cert_options
    {
      not_before: Time.now,
      email: "someone@example.org",
    }
  end

  def signing_cert_key(request)
    key_contents = Base64.decode64(JSON.parse(request.body).dig("publicKey", "content"))
    OpenSSL::PKey.read(key_contents)
  end
end
