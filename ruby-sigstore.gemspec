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

require_relative "lib/rubygems/sigstore/version"

Gem::Specification.new do |spec|
  spec.name          = "ruby-sigstore"
  spec.version       = Ruby::Sigstore::VERSION
  spec.authors       = ["Sigstore Community"]
  spec.email         = ["lhinds@redhat.com"]

  spec.summary       = %q(Sigstore signing client.)
  spec.description   = %q(Sigstore)
  spec.homepage      = "https://github.com/sigstore/ruby-sigstore"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["allowed_push_host"] = "http://mygemserver.com"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/sigstore/ruby-sigstore"
  spec.metadata["changelog_uri"] = "https://github.com/sigstore/ruby-sigstore/CHANGELOG.md"
  spec.cert_chain = ['certs/sigstore.pem']

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path("..", __FILE__)) do
    `git ls-files -z`.split("\x0").reject {|f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) {|f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "pp", "0.2.0"
  spec.add_runtime_dependency "openid_connect", "~> 1.2", ">= 1.2.0"
  spec.add_runtime_dependency "oa-openid", "~> 0.0.2"
  spec.add_runtime_dependency "omniauth-openid", "~> 2.0.1"
  spec.add_runtime_dependency "ruby-openid-apps-discovery", "~> 1.2.0"
  spec.add_runtime_dependency "launchy", "~> 2.5"
  spec.add_runtime_dependency "faraday_middleware", "~> 1.0.0"
  spec.add_runtime_dependency "config", "~> 3.1.0"
  spec.add_runtime_dependency "json-jwt", "~> 1.13.0"
end
