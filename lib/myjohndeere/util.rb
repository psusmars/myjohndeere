module MyJohnDeere
  class Util
    def self.build_path_headers_and_body(method, path, headers: {}, body: "", etag: nil)
      # in the case of following one of their paths, just clear out the base
      path = path.sub(MyJohnDeere.configuration.endpoint, '')
      path = "/#{path}" if not path.start_with?("/")
      # always trim platform from the beginning as we have that in our base
      path = path.sub(/\A\/?platform/, "")

      default_headers = nil
      if method == :post || method == :put then
        body = body.to_json() if body.is_a?(Hash)
        default_headers = MyJohnDeere::DEFAULT_POST_HEADER.dup
        content_length = body.length
        default_headers["Content-Length"] ||= body.length.to_s if content_length > 0
      else
        default_headers = MyJohnDeere::DEFAULT_REQUEST_HEADER
      end
      headers = default_headers.merge(headers || {})

      if REQUEST_METHODS_TO_PUT_PARAMS_IN_URL.include?(method) then
        if !etag.nil? then
          # Pass an empty string to have it start
          headers[MyJohnDeere::ETAG_HEADER_KEY] = etag
        end

        # we'll only accept hashes for the body for now
        if body.is_a?(Hash) then
          uri = URI.parse(path)
          new_query_ar = URI.decode_www_form(uri.query || '')
          
          # For reasons beyond me, these are specified as non-parameters
          special_parameters = {}
          SPECIAL_BODY_PARAMETERS.each do |sbp|
            special_parameters[sbp] = body.delete(sbp)
          end

          body.each do |key, val|
            new_query_ar << [key.to_s, val.to_s]
          end
          special_parameters.each do |key,val|
            next if val.nil?
            query_string = "#{key}=#{val}"
            uri.path = "#{uri.path};#{query_string}" if !uri.path.include?(query_string)
          end
          uri.query = URI.encode_www_form(new_query_ar)
          path = uri.to_s
        end
      end

      return path, headers, body
    end

    def self.handle_response_error_codes(response)
      headers = response.to_hash
      code = response.code.to_i
      body = response.body
      error = nil
      case code
      when 503
        error = ServerBusyError
      when 400, 404
        error = InvalidRequestError
      when 401
        error = AuthenticationError
      when 403
        error = PermissionError
      when 429
        error = RateLimitError
      when 500
        error = InternalServerError
      end
        
      if error.nil? then
        return
      else
        error = error.new(
          http_status: code, http_body: body,
          http_headers: headers)
        error.response = response
        raise error
      end
    end
  end
end