require "rubygems/sigstore/rekor/log_entry"
require "rubygems/sigstore/rekor/signature"

class Gem::Sigstore::Rekor::Rekord < Gem::Sigstore::Rekor::LogEntry
  include Gem::Sigstore::Rekor::Signature
end
