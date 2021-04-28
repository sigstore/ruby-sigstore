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

require "rubygems/sigstore/config"
require "rubygems/sigstore/crypto"

require 'json/jwt'
require "launchy"
require "openid_connect"

class OpenIDHandler 
    def initialize(priv_key)
        @priv_key = priv_key
    end

    def get_token()
        config = SigStoreConfig.new().config

        session = {}
        session[:state] = SecureRandom.hex(16)
        session[:nonce] = SecureRandom.hex(16)
        oidc_discovery = OpenIDConnect::Discovery::Provider::Config.discover! config.oidc_issuer

        server = TCPServer.new 5678
        webserv = Thread.new do
        connection = server.accept
        while (input = connection.gets)
            response = "You may close this browser"

            connection.print "HTTP/1.1 200 OK\r\n" +
                        "Content-Type: text/plain\r\n" +
                        "Content-Length: #{response.bytesize}\r\n" +
                        "Connection: close\r\n"
            connection.print "\r\n"
            connection.print response
            connection.close
            params = input.split('?')[1].split(' ')[0]     # chop off the verb / http version
            paramarray  = params.split('&')    # only handles two parameters
            Thread.current[:code] = paramarray[0].partition('=').last
            Thread.current[:state] = paramarray[1].partition('=').last
            break
        end
        ensure
        server.close
        end

        client = OpenIDConnect::Client.new(
        authorization_endpoint: oidc_discovery.authorization_endpoint,
        identifier: config.oidc_client,
        redirect_uri: "http://localhost:5678",
        secret: config.oidc_secret,
        token_endpoint: oidc_discovery.token_endpoint,
        )

        authorization_uri = client.authorization_uri(
        scope: ["openid", :email],
        state: session[:state],
        nonce: session[:nonce]
        )

        begin
        Launchy.open(authorization_uri)
        rescue
        # NOTE: ignore any exception, as the URL is printed above and may be
        #       opened manually
        puts "Cannot open browser automatically, please click on the link below:"
        puts authorization_uri
        end

        webserv.join

        # check state == webserv[:state]
        if webserv[:state] != session[:state]
        abort 'Invalid state value received from OIDC Provider'
        end

        client.authorization_code = webserv[:code]
        access_token = client.access_token!

        jwks = JSON.parse(OpenIDConnect.http_client.get_content(oidc_discovery.jwks_uri)).with_indifferent_access
        public_keys = JSON::JWK::Set.new jwks[:keys]

        begin
        decoded_access_token = JSON::JWT.decode(access_token.to_s,public_keys)
        rescue JSON::JWS::VerificationFailed => e
        abort 'JWT Verification Failed: ' + e.to_s
        else  #success
        decode_json = JSON.parse(decoded_access_token.to_json)
        end

        proof = Crypto.new().sign_proof(@priv_key, decode_json["email"])
        return proof, access_token
    end
end