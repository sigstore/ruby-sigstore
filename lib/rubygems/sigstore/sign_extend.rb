# Copyright 2021 The Sigstore Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module Gem
  module Sigstore
  end
end

require 'digest'
require 'fileutils'
require 'openssl'
require 'rubygems/package'
require 'rubygems/command_manager'
require "rubygems/sigstore/config"
require 'rubygems/sigstore/options'
require "rubygems/sigstore/crypto"
require "rubygems/sigstore/fulcio_api"
require "rubygems/sigstore/rekor_api"
require "rubygems/sigstore/openid"
require "rubygems/sigstore/gemfile"

Gem::CommandManager.instance.register_command :sign

# overde the generic gem build command to lay are own --sign option on top
b = Gem::CommandManager.instance[:build]
b.add_option("--sign", "Sign gem with sigstore.") do |value, options|
  Gem::Sigstore.options[:sign] = true
end

class Gem::Commands::BuildCommand
  alias_method :original_execute, :execute
  def execute
    config = Gem::Sigstore::Config.read

    if Gem::Sigstore.options[:sign]
      config = Gem::Sigstore::Config.read
      priv_key, _pub_key, enc_pub_key = Gem::Sigstore::Crypto.new.generate_keys
      proof, access_token = Gem::Sigstore::OpenID.new(priv_key).get_token
      puts ""

      fulcio_api = Gem::Sigstore::FulcioApi.new(token: access_token, host: config.fulcio_host)
      cert_response = fulcio_api.create(proof, enc_pub_key)

      # Run the gem build process (original_execute)
      original_execute

      gem_file = Gem::Sigstore::Gemfile.find_gemspec
      gem_file_signature = priv_key.sign gem_file.digest, gem_file.content

      content = <<~CONTENT

        sigstore signing operation complete."

        sending signiture & certificate chain to rekor."
      CONTENT
      puts content

      data = Gem::Sigstore::RekorApi::Data.new(gem_file.digest, gem_file_signature, gem_file.content)
      rekor_api = Gem::Sigstore::RekorApi.new(host: config.fulcio_host)
      rekor_response = rekor_api.create(cert_response, data)
      puts "rekor response: "
      pp rekor_response
    end
  end
end
