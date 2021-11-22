require 'helper'
require "rubygems/commands/verify_command"

class TestVerifyCommand < Gem::TestCase
  include RekorHelper

  def setup
    super

    @gem_path = gem_path("hello-world.gem")
    @cmd = Gem::Commands::VerifyCommand.new

    stub_rekor_search_index_by_digest
    stub_rekor_get_rekord_by_uuid
  end

  def test_verify
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
end
