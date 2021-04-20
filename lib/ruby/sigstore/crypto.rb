require 'openssl'

class Crypto 
    def initialize; end
    def generate_keys
        key = OpenSSL::PKey::EC.new('prime256v1').generate_key
        pkey = OpenSSL::PKey::EC.new(key.public_key.group)
        pkey.public_key = key.public_key
        return [key.to_pem, pkey.to_pem]
    end
end
