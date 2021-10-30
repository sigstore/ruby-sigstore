class Gem::Sigstore::FileSigner
  Data = Struct.new(:digest, :signature, :raw)

  def initialize(file:, pkey:, transparency_log:, cert:)
    @pkey = pkey
    @file = file
    @transparency_log = transparency_log
    @cert = cert
  end

  def run
    @transparency_log.create(@cert, data)
  end

  private

  def data
    @data ||= Data.new(@file.digest, signature, @file.content)
  end

  def signature
    @signature ||= @pkey.private_key.sign @file.digest, @file.content
  end
end

