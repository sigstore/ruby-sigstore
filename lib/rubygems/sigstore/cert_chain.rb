require "open-uri"
require "rubygems/sigstore/cert_extensions"

class Gem::Sigstore::CertChain
  PATTERN = /-----BEGIN CERTIFICATE-----(?:.|\n)+?-----END CERTIFICATE-----/.freeze

  def initialize(cert_pem)
    @cert_pem = cert_pem
  end

  def certificates
    @certificates ||= build_chain
  end

  def signing_cert
    certificates.last
  end

  def root_cert
    certificates.first
  end

  private

  def build_chain
    deserialize.tap do |chain|
      while chain.first&.issuing_certificate_uri do
        chain.prepend(chain.first.issuing_certificate)
      end
    end
  end

  def deserialize
    return [] unless @cert_pem
    @cert_pem.scan(PATTERN).map do |cert|
      cert = OpenSSL::X509::Certificate.new(cert)
      cert.extend(Gem::Sigstore::CertExtensions)
      cert
    end
  end
end
