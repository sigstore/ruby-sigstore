module Gem::Sigstore::CertExtensions
  def extension(oid)
    extensions_hash[oid]
  end

  def issuing_certificate_uri
    return @issuing_certificate_uri if defined?(@issuing_certificate_uri)
    @issuing_certificate_uri ||= begin
      aia = extension("authorityInfoAccess")
      aia.match(/http\S+/).to_s if aia.present?
    end
  end

  def issuing_certificate
    if issuing_certificate_uri.empty?
      raise "unsupported authorityInfoAccess value #{extension("authorityInfoAccess")}"
    end

    cert_pem = URI.open(issuing_certificate_uri).read
    issuer = OpenSSL::X509::Certificate.new(cert_pem)
    issuer.extend(Gem::Sigstore::CertExtensions)
    issuer
  end

  def subject_alt_name
    extension("subjectAltName")&.delete_prefix("email:")
  end

  private

  def extensions_hash
    @extensions_hash ||= extensions.each_with_object({}) do |ext, hash|
      hash[ext.oid] = ext.value
    end
  end
end
