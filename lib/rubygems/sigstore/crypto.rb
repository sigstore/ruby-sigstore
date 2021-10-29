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

class Crypto
  def initialize; end

  def generate_keys
    key = OpenSSL::PKey::RSA.generate(2048)
    pkey = key.public_key
    return [key, pkey, Base64.encode64(pkey.to_der)]
  end

  def sign_proof(priv_key, email)
    proof = priv_key.sign(OpenSSL::Digest::SHA256.new, email)
    return Base64.encode64(proof)
  end
end

# class Crypto
#     def initialize; end

#     def generate_keys
#         key = OpenSSL::PKey::EC.new('prime256v1').generate_key
#         pkey = OpenSSL::PKey::EC.new(key.public_key.group)
#         pkey.public_key = key.public_key
#         return [key, pkey, Base64.encode64(pkey.to_der)]
#     end

#     def sign_proof(priv_key, email)
#         proof = priv_key.sign(OpenSSL::Digest::SHA256.new, email)
#         return Base64.encode64(proof)
#     end
# end
