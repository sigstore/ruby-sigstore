module FulcioHelper
  include UrlHelper
  include SigstoreAuthHelper

  FULCIO_BASE_URL = 'https://fulcio.sigstore.dev/'

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

  def build_fulcio_cert_chain(public_signing_key, not_before: Time.now)
    ef = OpenSSL::X509::ExtensionFactory.new

    root_key = OpenSSL::PKey::RSA.new(1024)
    root_subject = "/O=sigstore.dev/CN=sigstore"

    root_cert = OpenSSL::X509::Certificate.new
    root_cert.subject = root_cert.issuer = OpenSSL::X509::Name.parse(root_subject)
    root_cert.not_before = Time.now
    root_cert.not_after = Time.now + 10.years
    root_cert.public_key = root_key.public_key
    root_cert.serial = 0x0
    root_cert.version = 2
    root_cert.add_extension(ef.create_extension("basicConstraints","CA:FALSE",true))
    root_cert.add_extension(ef.create_extension("keyUsage","keyCertSign, cRLSign", true))

    root_cert.sign(root_key, OpenSSL::Digest.new("SHA256"))

    leaf_cert = OpenSSL::X509::Certificate.new
    leaf_cert.issuer = OpenSSL::X509::Name.parse(root_subject)
    leaf_cert.not_before = not_before
    leaf_cert.not_after = not_before + 10.minutes
    leaf_cert.public_key = public_signing_key
    leaf_cert.serial = 0x0
    leaf_cert.version = 2
    leaf_cert.add_extension(ef.create_extension("basicConstraints","CA:TRUE",true))
    leaf_cert.add_extension(ef.create_extension("keyUsage","digitalSignature", true))
    leaf_cert.add_extension(ef.create_extension("extendedKeyUsage","codeSigning", true))
    leaf_cert.add_extension(ef.create_extension("authorityInfoAccess","caIssuers;URI:http://some-ca-authority.org/ca.crt", true))
    leaf_cert.add_extension(ef.create_extension("subjectAltName","email:someone@example.org", true))
    leaf_cert.sign(root_key, OpenSSL::Digest.new("SHA256"))

    [root_cert, leaf_cert].map(&:to_pem)
  end

  def signing_cert_key(request)
    key_contents = Base64.decode64(JSON.parse(request.body).dig("publicKey", "content"))
    OpenSSL::PKey.read(key_contents)
  end
end
