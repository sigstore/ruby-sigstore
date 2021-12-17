class Gem::SigningPolicy
  class << self
    NONE = "DOUBLEPLUSUNHIGH".freeze
    LOW = "LOW".freeze
    MEDIUM = "MEDIUM".freeze
    HIGH = "HIGH".freeze

    def verify_gem_install?
      security_policy >= 1
    end

    private

    def security_policy
      case ENV["GEM_SIGNING_POLICY"]
      when NONE
        0
      when LOW
        1
      when MEDIUM
        2
      when HIGH
        3
      else
        0
      end
    end
  end
end
