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

module Gem
  module Sigstore
  end
end

require "rubygems/sigstore/gemfile"

class Gem::Commands::VerifyCommand < Gem::Command
  def initialize
    super 'verify', "Opens the gem's documentation"
    add_option('--rekor-host HOST', 'Rekor host') do |value, options|
      options[:host] = value
    end
  end

  def execute
    gem_path = get_one_gem_name
    puts "verify \"#{gem_path}\""

    raise Gem::CommandLineError, "#{gem_path} is not a file" unless File.file?(gem_path)

    gemfile = Gem::Sigstore::Gemfile.new(gem_path)

    config = Gem::Sigstore::Config.read

    entries = HttpClient.new.get_rekor_entries(gemfile.digest, config.rekor_host)
    rekord_hashes = entries.map { |entry| rekord_from_entry(entry.values.first) }

    rekord = rekord_hashes.find { |rekord| valid_signature?(rekord, gemfile.digest, gemfile.content) }

    if rekord
      puts ":noice:, signed by #{signer_email(rekord)}"
    else
      puts "not :noice: thxkbye"
    end
  end

  private

  def rekord_from_entry(entry_hash)
    JSON.parse(Base64.decode64(entry_hash["body"]))
  end

  def valid_signature?(rekord_hash, digest, contents)
    # {
    #   "apiVersion"=>"0.0.1",
    #   "kind"=>"rekord",
    #   "spec"=>{
    #     "data"=>{
    #       "hash"=>{
    #         "algorithm"=>"sha256",
    #         "value"=>"230aed713b5d1cfce45228658bdb58e37502be1323f768fde0220e64233f1e32"
    #       }
    #     },
    #     "signature"=>{
    #       "content"=>"ngxsh3qbcWtjpZWxkdLcMA6hX61x/pmYf9LxN8MttwcJIaiwRNxiXeQWek0Y+5WiVD+fDZc42udM5OaEgBl3fjmU68NkLoe1WieTR/C+GJHlgjE69ZFLG80GwRgcP3hE4HiTYdk5UkCL8yFA2fJEgYnpLr8PhBOZoHZeLbt+9sQEXTOj6HqjSvvA6JLMSbJweXwUMP6EfjIUuEn2geKC2Hvh54tUu6sH+Hpk7EBADNDcBRL/57TX6OGJdku/Rrrkn9J5XhBaDzhZHr5vZVY86ZyB/NQYz3li2l3sbhLRQpIaUEQXdQmIP1AaJsPt27QIE6zJHMBJ2MUv1UMjYKsLGQ==",
    #       "format"=>"x509",
    #       "publicKey"=>{
    #         "content"=>"LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURkakNDQXYyZ0F3SUJBZ0lVQVAxSENMQnpnamtSYmp3bzFndkI3VXdoZHNFd0NnWUlLb1pJemowRUF3TXcKS2pFVk1CTUdBMVVFQ2hNTWMybG5jM1J2Y21VdVpHVjJNUkV3RHdZRFZRUURFd2h6YVdkemRHOXlaVEFlRncweQpNVEV3TWpreE9UVTNNVE5hRncweU1URXdNamt5TURFM01USmFNQUF3Z2dFaU1BMEdDU3FHU0liM0RRRUJBUVVBCkE0SUJEd0F3Z2dFS0FvSUJBUUM0ZnRNREJDczJ0K0FqWFAyUjhTNkUyaTdDbHVHeTBsRC9tYmgzRFpDZXc1UmwKd2FoN1pZTlZhSFg3UW1mK1hOZmkrVldubU4rVmNRWlZjaTJHRGVuZnBYRUM0SnhDUHplQXBPSWxVY1NYTWV5cgpLSWh3L2Z1YkMrN0NvaElvUE5MRjM2RGUvTzNvTFo3MStudUFqMTIvTDl5bTlhVnRxNDEvcG1XY2ExQWJ4WWFNCjQwUHNUNi84cENGa0MyTWRxWmllWEl1bVJWWmdJMXVHVGh2eVR1dDQ4Q2tXdHlyYWFZZ3VjVk5VK3gyL21YQWUKZHZQdHRJUmVYR000bGZxam5SRVIxY3BOZ1RYbmFZRitQNW9YZ2hueXAwTWk1ek5WL2hpVXlyaUd0TDRBSmVDMApUOUljVjQyTGNCOEdCMDFsNUYzTjdTY1NUaXZjNjU4UFFDWEJyUWpiQWdNQkFBR2pnZ0ZlTUlJQldqQU9CZ05WCkhROEJBZjhFQkFNQ0I0QXdFd1lEVlIwbEJBd3dDZ1lJS3dZQkJRVUhBd013REFZRFZSMFRBUUgvQkFJd0FEQWQKQmdOVkhRNEVGZ1FVSVl3Z1I5OURiS28yTVlTK2RjbXdBYklnakxVd0h3WURWUjBqQkJnd0ZvQVV5TVVkQUVHYQpKQ2t5VVNUckRhNUs3VW9HMCt3d2dZMEdDQ3NHQVFVRkJ3RUJCSUdBTUg0d2ZBWUlLd1lCQlFVSE1BS0djR2gwCmRIQTZMeTl3Y21sMllYUmxZMkV0WTI5dWRHVnVkQzAyTURObVpUZGxOeTB3TURBd0xUSXlNamN0WW1ZM05TMW0KTkdZMVpUZ3daREk1TlRRdWMzUnZjbUZuWlM1bmIyOW5iR1ZoY0dsekxtTnZiUzlqWVRNMllURmxPVFl5TkRKaQpPV1pqWWpFME5pOWpZUzVqY25Rd0p3WURWUjBSQVFIL0JCMHdHNEVaY205amFDNXNaV1psWW5aeVpVQnphRzl3CmFXWjVMbU52YlRBc0Jnb3JCZ0VFQVlPL01BRUJCQjVvZEhSd2N6b3ZMMmRwZEdoMVlpNWpiMjB2Ykc5bmFXNHYKYjJGMWRHZ3dDZ1lJS29aSXpqMEVBd01EWndBd1pBSXdjWlJFaWt1NVlDMGFmQjA4dzRIM1UrdEdvUTBCUzFvVQp4b1hqU0VzNUpuZk9YaDRrUWNldC90TmpvQytLdnhkWUFqQlhrT0hGMC81WTQ4RUN0SENHeTdDRWxSM1FKb1NkCjJSZVp6V3MwUmNreXl1U2JQb0FnUHlyM04rYXpkYkdDUHdzPQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg=="
    #       }
    #     }
    #   }
    # }

    entry_digest = rekord_hash.dig("spec", "data", "hash", "value")
    raise "Expecting a hash in #{rekord_hash}" unless entry_digest

    signature = Base64.decode64(rekord_hash.dig("spec", "signature", "content"))
    raise "Expecting a signature in #{rekord_hash}" unless entry_digest

    cert = Base64.decode64(rekord_hash.dig("spec", "signature", "publicKey", "content"))
    raise "Expecting a publicKey in #{rekord_hash}" unless entry_digest

    key = key_from_cert(cert)

    key.verify(gemfile.digest, signature, contents)
  end

  def key_from_cert(cert)
    cert = OpenSSL::X509::Certificate.new(cert)
    cert.public_key
  end

  def signer_email(rekord_hash)
    cert = Base64.decode64(rekord_hash.dig("spec", "signature", "publicKey", "content"))
    extensions = OpenSSL::X509::Certificate.new(cert).extensions.each_with_object({}) { |ext, hash| hash[ext.oid] = ext.value }
    extensions["subjectAltName"]&.delete_prefix("email:")
  end
end
