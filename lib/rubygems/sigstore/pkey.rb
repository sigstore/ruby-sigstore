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

require 'base64'
require 'openssl'

class Gem::Sigstore::PKey
  def initialize(private_key: nil)
    @private_key = private_key if private_key
  end

  def sign_proof(email)
    private_key.sign(OpenSSL::Digest::SHA256.new, email)
  end

  def public_key
    private_key.public_key
  end

  def private_key
    @private_key ||= OpenSSL::PKey::RSA.generate(2048)
  end
end
