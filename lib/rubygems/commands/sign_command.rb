require 'rubygems/command'

require 'json'
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
    puts "sign"

    options[:issuer] = "https://oauth2.sigstore.dev/auth"
    options[:client] = "sigstore"
    options[:secret] = ""

    session = {}
    session[:state] = SecureRandom.hex(16)
    session[:nonce] = SecureRandom.hex(16)

    result = OpenIDConnect::Discovery::Provider::Config.discover! options[:issuer]
    # pp result
    userinfo_endpoint = result.userinfo_endpoint
    puts userinfo_endpoint
    client = OpenIDConnect::Client.new(
      authorization_endpoint: result.authorization_endpoint,
      identifier: options[:client],
      redirect_uri: "http://localhost:5678",
      secret: options[:secret],
      token_endpoint: result.token_endpoint,
    )
    pp client

    authorization_uri = client.authorization_uri(
      scope: ["openid", :email],
      state: session[:state],
      nonce: session[:nonce]
    )
    puts authorization_uri
    
    begin
      Launchy.open(authorization_uri)
    rescue
      # NOTE: ignore any exception, as the URL is printed above and may be
      #       opened manually
      puts "Cannot open browser automatically, please click on the link above"
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
      puts input
      params = input.split('?')[1].split(' ')[0]     # chop off the verb / http version
      paramarray  = params.split('&')    # only handles two parameters
      code = paramarray[0].partition('=').last
      state = paramarray[1].partition('=').last
      break
    end
    client.authorization_code = code
    access_token = client.access_token!
    puts access_token
    # next step is to grab scopes and send to fulcio as part of proof
    client = OpenIDConnect::Client.new(
      identifier: options[:client],
      userinfo_endpoint: userinfo_endpoint
    )
    scope_token = OpenIDConnect::AccessToken.new(
      access_token: access_token,
      client: client
    )
    userinfo = scope_token.userinfo!
    pp userinfo.email
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
