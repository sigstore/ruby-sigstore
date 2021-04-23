require 'rubygems/command'
require "rubygems/sigstore/crypto"
require "rubygems/sigstore/http_client"

require 'json/jwt'
require "launchy"
require "openid_connect"
require "socket"

class Gem::Commands::SignCommand < Gem::Command
  def initialize
    super "sign", "Sign a gem"
    set_options
  end

  def arguments # :nodoc:
    "GEMNAME        name of gem to sign"
  end

  def defaults_str # :nodoc:
    ""
  end

  def usage # :nodoc:
    "gem sign GEMNAME"
  end

  def execute
    priv_key, pub_key = Crypto.new().generate_keys

    options[:issuer] = "https://oauth2.sigstore.dev/auth"
    options[:client] = "sigstore"
    options[:secret] = ""

    session = {}
    session[:state] = SecureRandom.hex(16)
    session[:nonce] = SecureRandom.hex(16)

    oidc_discovery = OpenIDConnect::Discovery::Provider::Config.discover! options[:issuer]

    client = OpenIDConnect::Client.new(
      authorization_endpoint: oidc_discovery.authorization_endpoint,
      identifier: options[:client],
      redirect_uri: "http://localhost:5678",
      secret: options[:secret],
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

    server = TCPServer.new 5678
    connection = server.accept
    while (input = connection.gets)
      response = "You may close this browser"

      connection.print "HTTP/1.1 200 OK\r\n" +
                  "Content-Type: text/plain\r\n" +
                  "Content-Length: #{response.bytesize}\r\n" +
                  "Connection: close\r\n"
      connection.close
      params = input.split('?')[1].split(' ')[0]     # chop off the verb / http version
      paramarray  = params.split('&')    # only handles two parameters
      code = paramarray[0].partition('=').last
      state = paramarray[1].partition('=').last
      break
    end

    client.authorization_code = code
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

    proof = Crypto.new().sign_proof(priv_key, decode_json["email"])
    cert_response = HttpClient.new().get_cert(access_token, proof, pub_key, options[:host])
    puts cert_response
  end

  private

  def set_options
    add_option("--fulcio-host HOST", "Fulcio host") do |value, options|
      options[:host] = value
    end
    add_option("--oidc-issuer ISSUER", "OIDC provider to be used to issue ID token") do |value, options|
      options[:issuer] = value
    end
    add_option("--oidc-client-id CLIENT", "Client ID for application") do |value, options|
      options[:client] = value
    end
    # THIS IS NOT A SECRET - IT IS USED IN THE NATIVE/DESKTOP FLOW.
    add_option("--oidc-client-secret SECRET", "Client secret for application") do |value, options|
      options[:secret] = value
    end
    add_option("--output FILE", "output file to write certificate chain to") do |value, options|
      options[:file] = value
    end
  end
end
