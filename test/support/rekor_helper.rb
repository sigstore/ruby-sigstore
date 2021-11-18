module RekorHelper
  include UrlHelper

  REKOR_BASE_URL = 'https://rekor.sigstore.dev/'

  def rekor_api_url(*path, **kwargs)
    url_regex(REKOR_BASE_URL, 'api', 'v1', path, **kwargs)
  end

  def rekor_log_entries_url
    rekor_api_url('log', 'entries')
  end

  def stub_rekor_create_log_entry(digest, body: {}, returning: {})
    stub_request(:post, rekor_log_entries_url)
      .with(
        headers: {
          content_type: 'application/json',
        },
        body: hash_including({
          kind: "rekord",
          apiVersion: "0.0.1",
          spec: hash_including({
            signature: hash_including({
              format: "x509",
              content: BASE64_ENCODED_PATTERN,
              publicKey: hash_including({
                content: BASE64_ENCODED_PATTERN,
              })
            }),
            data: hash_including({
              content: BASE64_ENCODED_PATTERN,
              hash: hash_including({
                algorithm: "sha256",
                value: digest
              })
            })
          })
        })
      )
      .to_return_json(
        build_rekord_entry(returning[:body] || {}),
        {
          status: 201
        }
      )
  end

  def build_rekord_entry(options)
    {
      dummy_entry_uuid: {
        body: "dummy rekord body",
        integratedTime: 1637154947,
        logID: "dummy rekord logID",
        logIndex: 864991,
        verification: {
          signedEntryTimestamp: "dummy timestamp signature"
        }
      }
    }.deep_merge(options)
  end
end
