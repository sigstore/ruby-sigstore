require 'test/unit'
require 'webmock/test_unit'
require 'rubygems/mock_gem_ui'
require 'json/jwt'

require 'rubygems/sigstore'

require 'support/webmock_helper'
require 'support/url_helper'
require 'support/sigstore_auth_helper'
require 'support/fulcio_helper'
require 'support/rekor_helper'

WebMock.disable_net_connect!(allow_localhost: true)

module Gem
  ##
  # Sets the default user interaction to a MockGemUi.

  module DefaultUserInteraction
    @ui = Gem::MockGemUi.new
  end

  class Gem::TestCase < Test::Unit::TestCase
    include Gem::DefaultUserInteraction

    BASE64_ENCODED_PATTERN = /[a-zA-Z0-9\+\/=\\]/.freeze

    def setup
      @back_ui = Gem::DefaultUserInteraction.ui
      @ui = Gem::MockGemUi.new
      # This needs to be a new instance since we call use_ui(@ui) when we want to capture output
      Gem::DefaultUserInteraction.ui = Gem::MockGemUi.new

      ENV["SIGSTORE_TEST"] = "1"
    end

    def teardown
      @back_ui.close
      ENV.delete("SIGSTORE_TEST")
    end

    def gem_path(name)
      File.join("test", "fixtures", "gems", name)
    end

    def gem_digest(path)
      OpenSSL::Digest::SHA256.new(File.read(path)).to_s
    end
  end
end
