require 'singleton'
require 'cgi'

class HTTPWrapper
  include Singleton

  attr_accessor :delegate, :mime_type, :username, :password

  attr_reader :data, :response, :connection

  def initialize
    @mime_type = "application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5"
    @username = ''
    @password = ''
    @data = NSMutableData.new
  end

  def send_request_to(url, args={})
    verb = args[:verb]
    parameters = args[:parameters]
    headers = args[:headers] || {}
    params = parameters ? parameters.collect{|name, value| "#{CGI.escape(name)}=#{CGI.escape(value)}"}.join('&') : ''

    if (verb == 'POST' || verb == 'PUT')
      content_type = 'application/x-www-form-urlencoded; charset=utf-8'
      request_url = NSURL.URLWithString(url)
    else
      content_type = 'text/html; charset=utf-8'
      request_url = NSURL.URLWithString(params.empty? ? url : "#{url}?#{params}")
    end

    #TODO: These should be default headers which are overrideable.
    headers['Content-Type']   = content_type
    headers['Accept']         = @mime_type
    headers['Cache-Control']  = 'no-cache'
    headers['Pragma']         = 'no-cache'
    headers['Connection']     = 'close' # Avoid HTTP 1.1 "keep alive" for the connection

    request = NSMutableURLRequest.requestWithURL(request_url, cachePolicy:NSURLRequestUseProtocolCachePolicy, timeoutInterval:60)
    request.setHTTPMethod(verb)

    # HTTPHeaders are case insensitive: http://www.w3.org/Protocols/rfc2616/rfc2616-sec4.html#sec4.2
    # NSMutableURLRequest automatically transforms them into a lowercase string with a capitalized first letters: FOO-BAR would become Foo-Bar.
    request.setAllHTTPHeaderFields(headers)
    request.setHTTPBody(params.dataUsingEncoding(NSUTF8StringEncoding)) unless verb == 'GET' || params.empty?

    start_connection(request)
  end

  def start_connection(request)
    @connection = NSURLConnection.alloc.initWithRequest(request, delegate:self, startImmediately:true)
  end

  def connection(conn, didReceiveResponse:response)
    @response = response
    @data.setLength(0)
  end

  def connection(conn, didReceiveData:data)
    @data.appendData(data)
  end

  def connectionDidFinishLoading(conn)
    @delegate.did_receive_data(@data, with_response:@response) if @delegate.respond_to?('did_receive_data:with_response:')
  end

  def connection(conn, didReceiveAuthenticationChallenge:challenge)
    if challenge.previousFailureCount == 0
      credential = NSURLCredential.credentialWithUser(@username, password:@password, persistence:NSURLCredentialPersistenceNone)
      challenge.sender.useCredential(credential, forAuthenticationChallenge:challenge)
    else
      @delegate.did_receive_authentication_challenge if @delegate.respond_to?(:did_receive_authentication_challenge)
    end
  end

  def connection(conn, didFailWithError:error)
    @delegate.did_fail_with_error(error) if @delegate.respond_to?(:did_fail_with_error)
  end
end
