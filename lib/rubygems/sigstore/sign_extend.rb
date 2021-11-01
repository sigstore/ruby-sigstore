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
require "rubygems/sigstore/cert_provider"
require "rubygems/sigstore/file_signer"
require "rubygems/sigstore/gem_signer"

Gem::CommandManager.instance.register_command :sign

# overde the generic gem build command to lay are own --sign option on top
b = Gem::CommandManager.instance[:build]
b.add_option("--sign", "Sign gem with sigstore.") do |value, options|
  Gem::Sigstore.options[:sign] = true
end

class Gem::Commands::BuildCommand
  alias_method :original_execute, :execute
  def execute
    if Gem::Sigstore.options[:sign]
      gemfile = Gem::Sigstore::Gemfile.new(get_one_gem_name)
      gem_signer = Gem::Sigstore::GemSigner.new(
        gemfile: gemfile,
        config: Gem::Sigstore::Config.read
      )
      # Run the gem build process only if openid auth was successful (original_execute)
      rekor_entry = gem_signer.run { original_execute }
      pp rekor_entry
    end
  end
end
