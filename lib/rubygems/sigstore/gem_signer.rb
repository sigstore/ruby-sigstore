class Gem::Sigstore::GemSigner
  Data = Struct.new(:digest, :signature, :raw)

  def initialize(gemfile:, config:, io: $stdout)
    @gemfile = gemfile
    @config = config
    @io = io
  end

  def run
    pkey = Gem::Sigstore::PKey.new
    cert = Gem::Sigstore::CertProvider.new(config: config, pkey: pkey).run

    yield if block_given?

    io.puts "Fulcio cert chain"
    io.puts cert
    io.puts
    io.puts "sending signiture & certificate chain to rekor."

    Gem::Sigstore::FileSigner.new(
      file: gemfile,
      pkey: pkey,
      transparency_log: Gem::Sigstore::RekorApi.new(host: config.rekor_host),
      cert: cert
    ).run
  end

  private

  attr_reader :gemfile, :config, :io
end
