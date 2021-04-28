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

require 'rubygems/command_manager'
require "rubygems/sigstore/config"
require 'rubygems/sigstore/options'
require "rubygems/sigstore/crypto"
require "rubygems/sigstore/http_client"
require "rubygems/sigstore/openid"

Gem::CommandManager.instance.register_command :sign

# overde the generic gem build command to lay are own --sign option on top
b = Gem::CommandManager.instance[:build]
b.add_option("--sign", "Sign gem with sigstore.") do |value, options|
  Gem::Sigstore.options[:sign] = true
end

class Gem::Commands::BuildCommand
  alias_method :original_execute, :execute
  def execute
    
    config = SigStoreConfig.new().config
    
    if Gem::Sigstore.options[:sign]
        config = SigStoreConfig.new().config
        priv_key, pub_key = Crypto.new().generate_keys
        proof, access_token = OpenIDHandler.new(priv_key).get_token
        cert_response = HttpClient.new().get_cert(access_token, proof, pub_key, config.fulcio_host)
        puts cert_response
    end
    # original_execute calls the native command
    original_execute
  end
end
