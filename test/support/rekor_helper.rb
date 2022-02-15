require 'rubygems/sigstore/gemfile'
require 'rubygems/sigstore/pkey'

module RekorHelper
  include UrlHelper
  include FulcioHelper

  REKOR_BASE_URL = 'https://rekor.sigstore.dev'.freeze

  def rekor_api_url(*path, **kwargs)
    url_regex(REKOR_BASE_URL, 'api', 'v1', path, **kwargs)
  end

  def rekor_log_entries_url
    rekor_api_url('log', 'entries')
  end

  def stub_rekor_create_rekord(gem_path: @gem_path, body: {}, returning: {})
    gem = Gem::Sigstore::Gemfile.new(gem_path)

    stub_request(:post, rekor_log_entries_url)
      .with(
        headers: {
          content_type: 'application/json',
        },
        body: hash_including(
          {
            kind: "hashedrekord",
            apiVersion: "0.0.1",
            spec: hash_including({
              signature: hash_including({
                format: "x509",
                content: BASE64_ENCODED_PATTERN,
                publicKey: hash_including({
                  content: BASE64_ENCODED_PATTERN,
                }),
              }),
              data: hash_including({
                hash: hash_including({
                  algorithm: "sha256",
                  value: gem.digest,
                }),
              }),
            }),
          }.merge(body) # deep_merge is incompatible with nested hash_including()
        )
      )
      .to_return_json(
        build_rekord_entry(returning[:body] || {}),
        {
          status: 201,
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
          signedEntryTimestamp: "dummy timestamp signature",
        },
      },
    }.deep_merge(options)
  end

  def rekor_index_retrieve_url
    rekor_api_url('index', 'retrieve')
  end

  def stub_rekor_search_index_by_digest(gem_path: @gem_path, body: {}, returning: nil)
    gem = Gem::Sigstore::Gemfile.new(gem_path)

    stub_request(:post, rekor_index_retrieve_url)
      .with(
        headers: {
          content_type: 'application/json',
        },
        body: {
          hash: "sha256:#{gem.digest}",
        },
      )
      .to_return_json(returning || ["dummy_entry_uuid"])
  end

  def rekor_log_entries_retrieve_url
    rekor_api_url('log', 'entries', 'retrieve')
  end

  def stub_rekor_get_rekords_by_uuid(
    uuids: ["dummy_entry_uuid"],
    returning: {
      "dummy_entry_uuid" => {
        log_entry_options: {},
        rekord_options: {},
        cert_options: {},
        gem_path: @gem_path,
      },
    }
  )
    stub_request(:post, rekor_log_entries_retrieve_url)
      .with(
        body: {
          entryUUIDs: uuids,
        }
      )
      .to_return_json(
        returning.map do |uuid, options|
          build_rekord_log_entry(
            uuid: uuid,
            **options
          )
        end
      )
  end

  def build_rekord_log_entry(uuid:, log_entry_options: {}, rekord_options: {}, cert_options: {}, gem_path: @gem_path)
    {
      uuid => {
        body: Base64.encode64(build_rekord(rekord_options, cert_options, gem_path).to_json),
        integratedTime: 1637154947,
        logID: "dummy rekord logID",
        logIndex: 864991,
        verification: {
          signedEntryTimestamp: "dummy timestamp signature",
        },
      },
    }.deep_merge(log_entry_options)
  end

  def build_rekord(rekord_options, cert_options, gem_path)
    gem = Gem::Sigstore::Gemfile.new(gem_path)
    pkey = Gem::Sigstore::PKey.new
    cert_chain = build_fulcio_cert_chain(pkey.public_key, signing_cert_options: cert_options)
    stub_get_ca_certificate(certificate: cert_chain.first)

    {
      "apiVersion": "0.0.1",
      "kind": "rekord",
      "spec": {
        "data": {
          "hash": {
            "algorithm": "sha256",
            "value": gem.digest,
          },
        },
        "signature": {
          "content": Base64.encode64(pkey.private_key.sign(OpenSSL::Digest.new('SHA256'), gem.content)),
          "format": "x509",
          "publicKey": {
            "content": Base64.encode64(cert_chain.last),
          },
        },
      },
    }.deep_merge(rekord_options)
  end

  def ca_authority_url(*path, **kwargs)
    url_regex(FULCIO_FAKE_CA_BASE_URL, path, **kwargs)
  end

  def stub_get_ca_certificate(certificate:, returning: {})
    stub_request(:get, ca_authority_url('ca.crt'))
      .to_return(
        {
          headers: {
            content_type: "application/octet-stream",
          },
          body: certificate,
        }.merge(returning)
      )
  end
end
