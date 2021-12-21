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
require "rubygems/user_interaction"
require 'rubygems/sigstore'

# gem install hooks
i = Gem::CommandManager.instance[:install]
i.add_option("--[no-]verify",
             'Verifies a local gem has been signed via sigstore.' +
             'This helps to ensure the gem has not been tampered with in transit.') do |value, options|
  Gem::Sigstore.options[:verify] = value
end

Gem.pre_install do |installer|
  begin
    verify = Gem::Sigstore.options[:verify] || Gem::SigningPolicy.verify_gem_install?
    if verify
      # A locally installed gem will sometimes not have a reference to the .gem file
      if (package = installer.package)
        gem_path = package.gem.path

        installer.say "Verifying #{gem_path}"

        raise Gem::CommandLineError, "#{gem_path} is not a file" unless File.file?(gem_path)

        gemfile = Gem::Sigstore::Gemfile.new(gem_path)
        verifier = Gem::Sigstore::GemVerifier.new(
          gemfile: gemfile,
          config: Gem::Sigstore::Config.read
        )
        verifier.run
      end
    end
  rescue StandardError => ex
    installer.alert_error(ex.message)
    installer.terminate_interaction(1)
  end
end
