require 'base64'
require 'openssl'

class Crypto 
    def initialize; end

    def generate_keys
        key = OpenSSL::PKey::EC.new('prime256v1').generate_key
        pkey = OpenSSL::PKey::EC.new(key.public_key.group)
        pkey.public_key = key.public_key
        return [key, Base64.encode64(pkey.to_der)]
    end

    def sign_proof(priv_key, email)
        proof = priv_key.sign(OpenSSL::Digest::SHA256.new, email)
        return Base64.encode64(proof)
    end
end
