class RestApi
  TIMEOUT = 10
  POLICY = NSURLRequestReloadIgnoringLocalCacheData

  def self.do_request(request_url, request_method, delegate)
    callback = HttpRequestCallback.new
    callback.delegate = delegate
    callback.buf = NSMutableData.new
    callback.response = nil

    url = NSURL.URLWithString(request_url)

    request = NSMutableURLRequest.requestWithURL(url, cachePolicy:POLICY, timeoutInterval:TIMEOUT)
		request.setHTTPMethod request_method
		#request.setValue("text/xml; charset=utf-8", forHTTPHeaderField:"Content-Type")

    callback.conn = NSURLConnection.alloc.initWithRequest(request, delegate:callback)
  end
end
