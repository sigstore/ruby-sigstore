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

require "faraday_middleware"
require "openssl"

class HttpClient
  def initialize
  end

  def get_cert(id_token, proof, pub_key, fulcio_host)
    connection = Faraday.new do |request|
      request.authorization :Bearer, id_token.to_s
      request.url_prefix = fulcio_host
      request.request :json
      request.response :json, content_type: /json/
      request.adapter :net_http
    end
    fulcio_response = connection.post("/api/v1/signingCert", { publicKey: { content: pub_key, algorithm: "ecdsa" }, signedEmailAddress: proof})
    return fulcio_response.body
  end

  def submit_rekor(cert_chain, data_digest, data_signature, certPEM, data_raw, rekor_host)
    # rekor uses a self signed certificate which failes the ssl check
    connection = Faraday.new(ssl: { verify: false }) do |request|
      # request.authorization :Bearer, id_token.to_s
      request.url_prefix = rekor_host
      request.request :json
      request.response :json, content_type: /json/
      request.adapter :net_http
    end
    rekor_response = connection.post("/api/v1/log/entries",
      {
        kind: "rekord",
          apiVersion: "0.0.1",
          spec: {
            signature: {
              format: "x509",
                  content: Base64.encode64(data_signature),
                  publicKey: {
                    content: Base64.encode64(cert_chain),
                  },
            },
              data: {
                content: Base64.encode64(data_raw),
                  hash: {
                    algorithm: "sha256",
                      value: data_digest,
                  },
              },
          },
      })
    return rekor_response.body
  end

  def get_rekor_entries(data_digest, rekor_host)
    # rekor uses a self signed certificate which fails the ssl check
    connection = Faraday.new(ssl: { verify: false }) do |request|
      request.url_prefix = rekor_host
      request.request :json
      request.response :json, content_type: /json/
      request.adapter :net_http
    end

    retrieve_response = connection.post("/api/v1/index/retrieve",
      {
        hash: "sha256:#{data_digest}",
      }
    )

    unless retrieve_response.status == 200
      raise "Unexpected response from POST /api/v1/index/retrieve:\n #{retrieve_response}"
    end

    retrieve_response.body.map do |uuid|
      entry_response = connection.get("api/v1/log/entries/#{uuid}")
      unless entry_response.status == 200
        raise "Unexpected response from GET api/v1/log/entries/#{uuid}:\n #{entry_response}"
      end

      entry_response.body
    end
  end
end
