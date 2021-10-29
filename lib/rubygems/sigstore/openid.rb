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

require 'base64'
require 'cgi'
require 'digest'
require 'json/jwt'
require "launchy"
require "openid_connect"

class OpenIDHandler
  def initialize(priv_key)
    @priv_key = priv_key
  end

  def get_token()
    config = SigStoreConfig.new.config
    session = {}
    session[:state] = SecureRandom.hex(16)
    session[:nonce] = SecureRandom.hex(16)
    oidc_discovery = OpenIDConnect::Discovery::Provider::Config.discover! config.oidc_issuer

    # oidc_discovery gem doesn't support code_challenge_methods yet, so we will just blindly include
    pkce = generate_pkce

    # If development env, used a fixed port
    if config.development == true
      server = TCPServer.new 5678
      server_addr = "5678"
    else
      server = TCPServer.new 0
      server_addr = server.addr[1].to_s
    end

    webserv = Thread.new do
      begin
        response = "You may close this browser"
        response_code = "200 OK"
        connection = server.accept
        while (input = connection.gets)
          begin
            # VERB PATH HTTP/1.1
            http_req = input.split(' ')
            if http_req.length != 3
              raise "invalid HTTP request received on callback"
            end
            params = CGI.parse(URI.parse(http_req[1]).query)
            if params["code"].length != 1 or params["state"].length != 1
              raise "multiple values for code or state returned in callback; unable to process"
            end
            Thread.current[:code] = params["code"][0]
            Thread.current[:state] = params["state"][0]
          rescue StandardError => e
            response = "Error processing request: #{e.message}"
            response_code = "400 Bad Request"
          end
          connection.print "HTTP/1.1 #{response_code}\r\n" +
                      "Content-Type: text/plain\r\n" +
                      "Content-Length: #{response.bytesize}\r\n" +
                      "Connection: close\r\n"
          connection.print "\r\n"
          connection.print response
          connection.close
          if response_code != "200 OK"
            raise response
          end
          break
        end
      ensure
        server.close
      end
    end

    webserv.abort_on_exception = true

    client = OpenIDConnect::Client.new(
        authorization_endpoint: oidc_discovery.authorization_endpoint,
        identifier: config.oidc_client,
        redirect_uri: "http://localhost:" + server_addr,
        secret: config.oidc_secret,
        token_endpoint: oidc_discovery.token_endpoint,
      )

    authorization_uri = client.authorization_uri(
        scope: ["openid", :email],
        state: session[:state],
        nonce: session[:nonce],
        code_challenge_method: pkce[:method],
        code_challenge: pkce[:challenge],
      )

    begin
      Launchy.open(authorization_uri)
  rescue
    # NOTE: ignore any exception, as the URL is printed above and may be
    #       opened manually
    puts "Cannot open browser automatically, please click on the link below:"
    puts ""
    puts authorization_uri
    end

    webserv.join

    # check state == webserv[:state]
    if webserv[:state] != session[:state]
      abort 'Invalid state value received from OIDC Provider'
    end

    client.authorization_code = webserv[:code]
    access_token = client.access_token!({code_verifier: pkce[:value]})

    provider_public_keys = oidc_discovery.jwks

    token = verify_token(access_token, provider_public_keys, config, session[:nonce])

    proof = Crypto.new.sign_proof(@priv_key, token["email"])
    return proof, access_token
  end

  private

  def generate_pkce()
    pkce = {}
    pkce[:method] = "S256"
    # generate 43 <= x <= 128 character random string; the length below will generate a 2x hex length string
    pkce[:value] = SecureRandom.hex(24)
    # compute SHA256 hash and base64-urlencode hash
    pkce[:challenge] = Base64.urlsafe_encode64(Digest::SHA256.digest(pkce[:value]), padding:false)
    return pkce
  end

  def verify_token(access_token, public_keys, config, nonce)
    begin
      decoded_access_token = JSON::JWT.decode(access_token.to_s,public_keys)
  rescue JSON::JWS::VerificationFailed => e
    abort 'JWT Verification Failed: ' + e.to_s
    else #success
      token = JSON.parse(decoded_access_token.to_json)
    end

    # verify issuer matches
    if token["iss"] != config.oidc_issuer
      abort 'Mismatched issuer in OIDC ID Token'
    end

    # verify it was intended for me
    if token["aud"] != config.oidc_client
      abort 'OIDC ID Token was not intended for this use'
    end

    # verify token has not expired (iat < now <= exp)
    now = Time.now.to_i
    if token["iat"] > now or now > token["exp"]
      abort 'OIDC ID Token is expired'
    end

    # verify nonce if present in token
    if token.key?("nonce") and token["nonce"] != nonce
      abort 'OIDC ID Token has incorrect nonce value'
    end

    # ensure that the OIDC provider has verified the email address
    # note: this may have happened some time in the past
    if token["email_verified"] != true
      abort 'Email address in OIDC token has not been verified by provider'
    end

    return token
  end
end
