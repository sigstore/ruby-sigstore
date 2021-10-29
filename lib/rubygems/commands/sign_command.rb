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

require 'rubygems/command'
require "rubygems/sigstore/config"
require "rubygems/sigstore/crypto"
require "rubygems/sigstore/http_client"
require "rubygems/sigstore/openid"

require 'json/jwt'
require "launchy"
require "openid_connect"
require "socket"

class Gem::Commands::SignCommand < Gem::Command
  def initialize
    super "sign", "Sign a gem"
  end

  def arguments # :nodoc:
    "GEMNAME        name of gem to sign"
  end

  def defaults_str # :nodoc:
    ""
  end

  def usage # :nodoc:
    "gem sign GEMNAME"
  end

  def execute
    config = SigStoreConfig.new.config
    priv_key, _pub_key, enc_pub_key = Crypto.new.generate_keys
    proof, access_token = OpenIDHandler.new(priv_key).get_token
    cert_response = HttpClient.new.get_cert(access_token, proof, enc_pub_key, config.fulcio_host)
    puts "Fulcio cert chain"
    print cert_response
    puts ""

    gem_file_path = get_one_gem_name
    gem_file = File.read(gem_file_path)
    gem_file_digest = OpenSSL::Digest::SHA256.new(gem_file)
    gem_file_signature = priv_key.sign gem_file_digest, gem_file

    content = <<~CONTENT

      sigstore signing operation complete."

      sending signiture & certificate chain to rekor."
    CONTENT
    puts content

    rekor_response = HttpClient.new.submit_rekor(cert_response, gem_file_digest, gem_file_signature, nil, Base64.encode64(gem_file), config.rekor_host)
    puts "rekor response: "
    pp rekor_response
  end
end
