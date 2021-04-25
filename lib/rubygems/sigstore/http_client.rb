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

class HttpClient
    def initialize; end
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
end
