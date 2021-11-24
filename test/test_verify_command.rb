require 'helper'
require "rubygems/commands/verify_command"

class TestVerifyCommand < Gem::TestCase
  include RekorHelper

  def setup
    super

    @gem_path = gem_path("hello-world.gem")
    @cmd = Gem::Commands::VerifyCommand.new

    stub_rekor_search_index_by_digest
    stub_rekor_get_rekords_by_uuid
  end

  def test_one_non_maintainer_signature
    @cmd.options[:args] = [@gem_path]

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
    @cmd.options[:args] = [@gem_path]
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
end
