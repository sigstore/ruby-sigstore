class Gem::Sigstore::RekordEntry
  def initialize(entry)
    @entry = entry
  end

  private

  def body
    @body ||= JSON.parse(Base64.decode64(@entry["body"]))
  end

  def valid_signature?(digest, contents)
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

    public_key = cert.public_key
    public_key.verify(digest, signature, contents)
  end

  def cert
    @cert ||= begin
      cert = Base64.decode64(body.dig("spec", "signature", "publicKey", "content"))
      raise "Expecting a publicKey in #{body}" unless cert
      OpenSSL::X509::Certificate.new(cert)
    end
  end

  def signature
    @signature ||= begin
      signature = Base64.decode64(body.dig("spec", "signature", "content"))
      raise "Expecting a signature in #{body}" unless signature
      signature
    end
  end

  def signer_email
    extensions["subjectAltName"]&.delete_prefix("email:")
  end

  def extensions
    @extensions ||= cert.extensions.each_with_object({}) do |ext, hash|
      hash[ext.oid] = ext.value
    end
  end
end

