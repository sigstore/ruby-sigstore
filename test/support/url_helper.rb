module UrlHelper
  BASE64_ENCODED_PATTERN = /[a-zA-Z0-9\+\/=\\]/

  def url_regex(base, *path, **kwargs)
    escape = lambda { |v| v.is_a?(String) ? Regexp.escape(v) : v.to_s }

    params = [base, path]
      .flatten
      .map { |param| escape.call(param) }

    url = File.join(params)
    kwargs = kwargs.delete_if { |_, v| v.blank? }
    unless kwargs.blank?
      url += Regexp.escape('?')
      query = kwargs
        .map { |k, v| [escape.call(k), escape.call(v)].join('=') }
        .join('&')
      url += query
    end
    /^#{url}$/
  end
end
