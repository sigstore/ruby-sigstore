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

require "rubygems/sigstore/config"
require "rubygems/sigstore/gemfile"
require "rubygems/sigstore/gem_verifier"

class Gem::Commands::VerifyCommand < Gem::Command
  def initialize
    super 'verify', "Opens the gem's documentation"
    add_option('--rekor-host HOST', 'Rekor host') do |value, options|
      options[:host] = value
    end
  end

  def execute
    gem_path = get_one_gem_name
    say "Verifying #{gem_path}"

    raise Gem::CommandLineError, "#{gem_path} is not a file" unless File.file?(gem_path)

    gemfile = Gem::Sigstore::Gemfile.new(gem_path)
    verifier = Gem::Sigstore::GemVerifier.new(
      gemfile: gemfile,
      config: Gem::Sigstore::Config.read
    )
    verifier.run
  end
end
