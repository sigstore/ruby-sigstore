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
