require 'helper'
require "rubygems/commands/sign_command"

class TestSignCommand < Gem::TestCase
  include SigstoreAuthHelper
  include FulcioHelper
  include RekorHelper

  def setup
    super

    @gem_path = gem_path("hello-world.gem")
    @cmd = Gem::Commands::SignCommand.new

    stub_sigstore_auth_get_openid_config
    stub_sigstore_auth_create_token
    stub_sigstore_auth_get_keys
    stub_fulcio_create_signing_cert
    stub_rekor_create_log_entry(gem_digest(@gem_path))
  end

  def test_sign
    @cmd.options[:args] = [@gem_path]

    use_ui @ui do
      @cmd.execute
    end

    output = @ui.output.split "\n"
    assert_equal "Fulcio certificate chain", output.shift
    assert_certificate(output) # root certificate
    assert_certificate(output) # leaf certificate
    assert_empty output.shift
    assert_equal "Sending gem digest, signature & certificate chain to transparency log.", output.shift
    assert_equal "https://rekor.sigstore.dev/api/v1/log/entries/dummy_entry_uuid", output.shift
    assert_equal [], output
  end

  def assert_certificate(output)
    assert_equal "-----BEGIN CERTIFICATE-----", output.shift
    assert_match BASE64_ENCODED_PATTERN, output.shift until output.first == "-----END CERTIFICATE-----"
    assert_equal "-----END CERTIFICATE-----", output.shift
  end
end
