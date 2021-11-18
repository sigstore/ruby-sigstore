module WebMock
  class RequestStub
    def to_return_json(hash = {}, options = {})
      options[:body] = hash.to_json
      result = options.merge(headers: { "Content-Type" => "application/json" })
      to_return(result)
    end
  end
end
