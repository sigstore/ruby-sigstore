require 'rubygems/command'

require "openid_connect"

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

    options[:issuer] = "https://accounts.google.com"
    options[:client] = "237800849078-rmntmr1b2tcu20kpid66q5dbh1vdt7aj.apps.googleusercontent.com"
    options[:secret] = "CkkuDoCgE2D_CCRRMyF_UIhS"

    session = {}
    session[:state] = SecureRandom.hex(16)
    session[:nonce] = SecureRandom.hex(16)

    result = OpenIDConnect::Discovery::Provider::Config.discover! options[:issuer]
    pp result
    
    client = OpenIDConnect::Client.new(
      authorization_endpoint: result.authorization_endpoint,
      identifier: options[:client],
      redirect_uri: "http://localhost:5556/auth/callback",
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
    
    # NOTE: this do not work across OS
    `xdg-open "#{authorization_uri}"`
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
