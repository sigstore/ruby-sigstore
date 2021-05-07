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

# require 'rubygems/commands'
# require 'minitar'
require 'digest'
require 'fileutils'
require 'open3'
require 'openssl'
require 'rubygems/package'
require 'rubygems/command_manager'
require "rubygems/sigstore/config"
require 'rubygems/sigstore/options'
require "rubygems/sigstore/crypto"
require "rubygems/sigstore/http_client"
require "rubygems/sigstore/openid"

Gem::CommandManager.instance.register_command :sign

def find_gemspec(glob = "*.gemspec")
    gemspecs = Dir.glob(glob).sort

    if gemspecs.size > 1
      alert_error "Multiple gemspecs found: #{gemspecs}, please specify one"
      terminate_interaction(1)
    end

    gemspecs.first
end

# overde the generic gem build command to lay are own --sign option on top
b = Gem::CommandManager.instance[:build]
b.add_option("--sign", "Sign gem with sigstore.") do |value, options|
  Gem::Sigstore.options[:sign] = true
end

class Gem::Commands::BuildCommand
  alias_method :original_execute, :execute
  def execute

    config = SigStoreConfig.new().config

    if Gem::Sigstore.options[:sign]
        config = SigStoreConfig.new().config
        priv_key, pub_key, enc_pub_key = Crypto.new().generate_keys
        proof, access_token = OpenIDHandler.new(priv_key).get_token
        cert_response = HttpClient.new().get_cert(access_token, proof, enc_pub_key, config.fulcio_host)
        certPEM, rootPem = cert_response.split(/\n{2,}/)
        puts certPEM
        puts rootPem
        # Run the gem build process (original_execute)
        original_execute

        # Find the gemspec file for the project
        gemspec_file = find_gemspec()
        spec = Gem::Specification::load(gemspec_file)

        # Unwrap files for signing
        File.open("#{spec.full_name}.gem", "rb") do |file|
            Gem::Package::TarReader.new(file) do |tar|
                tar.each do |entry|
                    if entry.file?
                        FileUtils.mkdir_p(File.dirname(entry.full_name))
                        File.open(entry.full_name, "wb") do |f|
                        f.write(entry.read)
                        end
                        File.chmod(entry.header.mode, entry.full_name)
                    end
                end
            end
        end

        puts "updating #{spec.full_name}.gem with signed materials"

        checksums_file = File.read('checksums.yaml.gz')
        checksums_digest = OpenSSL::Digest::SHA256.new(checksums_file)
        checksums_signature = priv_key.sign checksums_digest, checksums_file
        File.open('checksums.yaml.gz.sig', 'wb') do |f|
            f.write(checksums_signature)
        end

        metadata_file = File.read('metadata.gz')
        metadata_digest = OpenSSL::Digest::SHA256.new(metadata_file)
        metadata_signature = priv_key.sign metadata_digest, metadata_file
        File.open('metadata.gz.sig', 'wb') do |f|
            f.write(metadata_signature)
        end

        data_file = File.read('data.tar.gz')
        data_digest = OpenSSL::Digest::SHA256.new(data_file)
        data_signature = priv_key.sign data_digest, data_file
        File.open('metadata.gz.sig', 'wb') do |f|
            f.write(data_signature)
        end

        # TODO: Yeah, I know.
        Open3.popen3("tar -cvf #{spec.full_name}_signed.gem data.tar.gz data.tar.gz.sig metadata.gz metadata.gz.sig checksums.yaml.gz checksums.yaml.gz.sig") do |stdin, stdout, stderr, thread|
            puts stdout.read.chomp
        end

        puts "sigstore signing operation complete"

        rekor_response = HttpClient.new().submit_rekor(pub_key, data_digest, data_signature, certPEM, Base64.encode64(data_file), config.rekor_host)
        puts rekor_response  
    end
  end
end
