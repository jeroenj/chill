class HttpRequestCallback
	attr_accessor :delegate, :buf, :response, :conn
	
	def cancel
		if @conn
			@conn.cancel
			@conn = nil
		end
	end
	
	def connection(conn, didReceiveResponse:res)
		return if @conn != conn
		@response = res
	end
	
	def connectionDidFinishLoading(conn)
		if @response
			code = @response.statusCode
			if code.to_s =~ /^20[01]$/
				@delegate.call(@buf)
				else
				@delegate.call(false)
			end
		end
		@conn = nil
	end
	
	def connection(conn, didReceiveData:data)
		return if @conn != conn
		@buf.appendData(data)
	end
	
	def connection(conn, didFailWithError:err)
		if @conn == conn
			@delegate.call(false)
		end
		@conn = nil
	end
	
	def connection(conn, willSendRequest:req, redirectResponse:res)
		return nil if @conn != conn
		if res && res.statusCode == 302
			@delegate.call(req.URL.to_s)
			@conn = nil
			nil
			else
			req
		end
	end
end
