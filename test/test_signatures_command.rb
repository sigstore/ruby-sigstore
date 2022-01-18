require 'helper'
require "rubygems/commands/signatures_command"

class TestSignaturesCommand < Gem::TestCase
  include SigstoreAuthHelper
  include FulcioHelper
  include RekorHelper

  def setup
    super

    @gem_path = gem_path("hello-world.gem")
    @cmd = Gem::Commands::SignaturesCommand.new
  end

  def test_no_options
    @cmd.handle_options %W[#{@gem_path}]
    stub_rekor_search_index_by_digest(returning: [])

    use_ui @ui do
      @cmd.execute
    end

    output = @ui.output.split "\n"
    assert_equal "Verifying #{@gem_path}", output.shift
    assert_match /No valid signatures found for digest/, output.shift
    assert_equal [], output
  end

  def test_sign
    @cmd.handle_options %W[--sign #{@gem_path}]
    stub_signing

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

  def test_static_sign
    @cmd.handle_options %W[--sign --identity-token #{access_token} #{@gem_path}]
    stub_signing

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

  def test_verify_unsigned_gem
    @cmd.handle_options %W[--verify #{@gem_path}]
    stub_rekor_search_index_by_digest(returning: [])

    use_ui @ui do
      @cmd.execute
    end

    output = @ui.output.split "\n"
    assert_equal "Verifying #{@gem_path}", output.shift
    assert_match /No valid signatures found for digest/, output.shift
    assert_equal [], output
  end

  def test_one_non_maintainer_signature
    @cmd.handle_options %W[--verify #{@gem_path}]
    stub_rekor_search_index_by_digest
    stub_rekor_get_rekords_by_uuid

    use_ui @ui do
      @cmd.execute
    end

    output = @ui.output.split "\n"
    assert_equal "Verifying #{@gem_path}", output.shift
    assert_equal ":noice:", output.shift
    assert_equal "Signed by non-maintainer: someone@example.org", output.shift
    assert_equal [], output
  end

  def test_maintainer_signature_and_non_maintainer_signature
    @cmd.handle_options %W[--verify #{@gem_path}]
    uuids = ["maintainer_entry_uuid", "dummy_entry_uuid"]
    stub_rekor_search_index_by_digest(returning: uuids)
    stub_rekor_get_rekords_by_uuid(
      uuids: uuids,
      returning: {
        uuids.first => {
          cert_options: {
            email: "rubygems.org@n13.org", # email set in the spec for hello-world.gem
          },
        },
        uuids.last => {},
      }
    )

    use_ui @ui do
      @cmd.execute
    end

    output = @ui.output.split "\n"
    assert_equal "Verifying #{@gem_path}", output.shift
    assert_equal ":noice:", output.shift
    assert_equal "Signed by maintainer: rubygems.org@n13.org", output.shift
    assert_equal "Signed by non-maintainer: someone@example.org", output.shift
    assert_equal [], output
  end

  def test_sign_and_verify
    @cmd.handle_options %W[--sign --verify #{@gem_path}]
    stub_signing
    stub_rekor_search_index_by_digest
    stub_rekor_get_rekords_by_uuid

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
    assert_equal "Verifying #{@gem_path}", output.shift
    assert_equal ":noice:", output.shift
    assert_equal "Signed by non-maintainer: someone@example.org", output.shift
    assert_equal [], output
  end

  def test_nonexistent_file
    @cmd.handle_options %W[not_a_file]

    use_ui @ui do
      e = assert_raise Gem::CommandLineError do
        @cmd.execute
      end

      assert_equal "not_a_file is not a file", e.message
    end
  end

  def test_rejects_files_that_are_not_gems
    @cmd.handle_options %W[./test/fixtures/not_a_gem]

    use_ui @ui do
      e = assert_raise Gem::CommandLineError do
        @cmd.execute
      end

      assert_equal "./test/fixtures/not_a_gem is not a valid gem", e.message
    end
  end

  def assert_certificate(output)
    assert_equal "-----BEGIN CERTIFICATE-----", output.shift
    assert_match BASE64_ENCODED_PATTERN, output.shift until output.first == "-----END CERTIFICATE-----"
    assert_equal "-----END CERTIFICATE-----", output.shift
  end

  def stub_signing(gems: [@gem_path])
    stub_sigstore_auth_get_openid_config
    stub_sigstore_auth_create_token
    stub_sigstore_auth_get_keys
    stub_fulcio_create_signing_cert
    gems.each do |gem|
      stub_rekor_create_rekord(gem_path: gem)
    end
  end
end
