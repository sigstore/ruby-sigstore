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

require 'rubygems/command'
require "rubygems/sigstore/config"
require "rubygems/sigstore/crypto"
require "rubygems/sigstore/fulcio_api"
require "rubygems/sigstore/openid"
require "rubygems/sigstore/gemfile"
require "rubygems/sigstore/cert_provider"
require "rubygems/sigstore/file_signer"
require "rubygems/sigstore/gem_signer"

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
    gemfile = Gem::Sigstore::Gemfile.new(get_one_gem_name)
    rekor_entry = Gem::Sigstore::GemSigner.new(
      gemfile: gemfile,
      config: Gem::Sigstore::Config.read
    ).run
    pp rekor_entry
  end
end
