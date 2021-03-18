class Gem::Commands::SignCommand < Gem::Command
  def initialize
    super 'sign', 'Sign'
    add_option('--fulcio-host HOST', 'Fulcio host') do |value, options|
      options[:host] = value
    end
  end

  def execute
    puts "sign"
  end
end