class Gem::Commands::VerifyCommand < Gem::Command
  def initialize
    super 'verify', "Opens the gem's documentation"
    add_option('--fulcio-host HOST', 'Fulcio host') do |value, options|
      options[:host] = value
    end
  end

  def execute
    puts "verify"
  end
end