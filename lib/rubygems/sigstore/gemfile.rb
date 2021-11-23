require 'openssl'
require 'rubygems/package'
require 'digest'
require 'fileutils'

class Gem::Sigstore::Gemfile
  class << self
    def find_gemspec(glob = "*.gemspec")
      gemspecs = Dir.glob(glob).sort

      if gemspecs.size > 1
        alert_error "Multiple gemspecs found: #{gemspecs}, please specify one"
        terminate_interaction(1)
      end

      new(gemspecs.first)
    end
  end

  def initialize(path)
    @path = path
  end

  def path
    @path
  end

  def content
    @content ||= File.read(path)
  end

  def digest
    @digest ||= OpenSSL::Digest::SHA256.new(content)
  end

  def package
    @package ||= Gem::Package.new(path)
  end

  def spec
    package.spec
  end

  def maintainer?(email)
    maintainers.include?(email)
  end

  def maintainers
    Array(spec.email)
  end
end
