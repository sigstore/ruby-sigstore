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
require 'rubygems/sigstore'

require 'json/jwt'
require 'launchy'
require 'openid_connect'
require 'socket'

class Gem::Commands::SignaturesCommand < Gem::Command
  SIGNING_OPTIONS = [:sign, :verify].freeze

  def initialize
    super "signatures", "Create and verify gem signatures"

    add_option("-s", "--[no-]sign", "Sign the gem(s)") do |value, options|
      options[:sign] = value
    end

    add_option("-v", "--[no-]verify", "Verify gem signatures") do |value, options|
      options[:verify] = value
    end

    add_option("--identity-token TOKEN", String,
               "Provide a static token for signing in automated environments") do |value, options|
      options[:identity_token] = value
    end
  end

  def arguments # :nodoc:
    "GEMNAME        name of gem to sign or verify"
  end

  def defaults_str # :nodoc:
    ""
  end

  # def usage # :nodoc:
  #   "gem signatures GEMNAME"
  # end

  def execute
    gem_path = get_one_gem_name
    raise Gem::CommandLineError, "#{gem_path} is not a file" unless File.file?(gem_path)

    gemfile = Gem::Sigstore::Gemfile.new(gem_path)

    sign(gemfile) if options[:sign]
    verify(gemfile) if verify_signatures?
  end

  private

  def sign(gemfile)
    rekor_entry = Gem::Sigstore::GemSigner.new(
      gemfile: gemfile,
      config: Gem::Sigstore::Config.read,
      identity_token: options[:identity_token],
    ).run

    say log_entry_url(rekor_entry)
  end

  def verify_signatures?
    if options.key?(:verify)
      options[:verify]
    else
      default_verify_behavior
    end
  end

  def default_verify_behavior
    # Only verify signatures if there are no other signature-related options present.
    options.slice(*SIGNING_OPTIONS).empty?
  end

  def verify(gemfile)
    say "Verifying #{gemfile.path}"

    verifier = Gem::Sigstore::GemVerifier.new(
      gemfile: gemfile,
      config: Gem::Sigstore::Config.read
    )
    verifier.run
  end

  def log_entry_url(rekor_entry)
    "#{Gem::Sigstore::Config.read.rekor_host}/api/v1/log/entries/#{rekor_entry.keys.first}"
  end
end
