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

require 'digest'
require 'fileutils'
require 'openssl'
require 'rubygems/package'
require 'rubygems/command_manager'
require "rubygems/sigstore/config"
require 'rubygems/sigstore/options'
require "rubygems/sigstore/crypto"
require "rubygems/sigstore/http_client"
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
    config = SigStoreConfig.new.config

    if Gem::Sigstore.options[:sign]
      config = SigStoreConfig.new.config
      priv_key, _pub_key, enc_pub_key = Crypto.new.generate_keys
      proof, access_token = OpenIDHandler.new(priv_key).get_token
      puts ""
      cert_response = HttpClient.new.get_cert(access_token, proof, enc_pub_key, config.fulcio_host)
      certPEM, _rootPem = cert_response.split(/\n{2,}/)

      # Run the gem build process (original_execute)
      original_execute

      gem_file = Gem::Sigstore::Gemfile.find_gemspec
      gem_file_signature = priv_key.sign gem_file.digest, gem_file.content

      content = <<~CONTENT

        sigstore signing operation complete."

        sending signiture & certificate chain to rekor."
      CONTENT
      puts content

      rekor_response = HttpClient.new.submit_rekor(cert_response, gem_file.digest, gem_file_signature, certPEM, gem_file.content, config.rekor_host)
      puts "rekor response: "
      pp rekor_response
    end
  end
end
