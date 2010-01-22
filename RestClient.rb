class RestClient
  attr_accessor :request_url, :request_method, :output, :indicator, :parameters_table, :request_headers

  attr_accessor :engine
  attr_accessor :parameters_datasource

  def init
    if super
      @engine = Wrapper.new
      @engine.delegate = self
      self
    end
  end

  def awakeFromNib
    @parameters = []
    @http_headers = []
    @parameters_table.dataSource = self
    @request_headers.dataSource = self
  end


  # TableView Actions
  def numberOfRowsInTableView(view)
    case view.tag
    when 0 # parameters_table
      @parameters.size
    when 1 # request_headers
      @http_headers.size
    end
  end

  def tableView(view, objectValueForTableColumn:column, row:index)
    parameter = case view.tag
    when 0 # parameters_table
      @parameters[index]
    when 1 # request_headers
      @http_headers[index]
    end

    case column.identifier
    when 'name'
      parameter.name
    when 'value'
      parameter.value
    end
  end

  def tableView(view, setObjectValue:object, forTableColumn:column, row:index)
    parameter = case view.tag
    when 0 # parameters_table
      @parameters[index]
    when 1 # request_headers
      @http_headers[index]
    end

    case column.identifier
    when 'name'
      parameter.name = object
    when 'value'
      parameter.value = object
    end
  end


  # GUI Actions
  def rest_call(sender)
    url = NSURL.URLWithString(request_url.stringValue)
    verb = request_method.titleOfSelectedItem

    if @parameters.size > 0
      parameters = {}
      # paramters dictionary
      @parameters.each do |parameter|
        parameters[parameter.name] = parameter.value
      end
    else
      parameters = nil
    end

    start_indicator
    output.string = ''

    @engine.sendRequestTo(url, usingVerb:verb, withParameters:parameters)
  end

  def add_parameter(sender)
    parameter = Parameter.new
    parameter.name = ''
    parameter.value = ''
    @parameters << parameter
    @parameters_table.reloadData
    @parameters_table.editColumn(0, row:@parameters_table.numberOfRows-1, withEvent:nil, select:true)
  end

  def remove_paramter(sender)
    index = parameters_table.selectedRow

    if index >= 0
      parameter = @parameters.objectAtIndex(index)
      @parameters.delete(parameter)
      @parameters_table.reloadData
    end
  end


  # REST Wrapper Delegates
  def wrapper(engine, didRetrieveData:data)
    response = engine.httpResponse
    headers = response.allHeaderFields

    @http_headers.clear
    headers.each_pair do |key, value|
      http_header = Parameter.new
      http_header.name = key
      http_header.value = value
      @http_headers << http_header
    end
    @request_headers.reloadData

    text = engine.responseAsText
    if text
      output.string = text
      stop_indicator
    end
  end

  def wrapperHasBadCredentials(wrapper)
    stop_indicator
    alert = NSAlert.alertWithMessageText("Bad credentials!", defaultButton:"OK", alternateButton:nil, otherButton:nil, informativeTextWithFormat:nil)
    alert.runModal
  end

  def wrapper(wrapper, didCreateResourceAtURL:url)
    stop_indicator
    alert = NSAlert.alertWithMessageText("Resource created at #{url}", defaultButton:"OK", alternateButton:nil, otherButton:nil, informativeTextWithFormat:nil)
    alert.runModal
  end

  def wrapper(wrapper, didFailWithError:error)
    stop_indicator
    alert = NSAlert.alertWithError(error)
    alert.runModal
  end

  #def wrapper(wrapper, didReceiveStatusCode:statusCode)
  #	stop_indicator
  #	alert = NSAlert.alertWithMessageText("Status code not OK", defaultButton:"OK", alternateButton:nil, otherButton:nil, informativeTextWithFormat:"I am an alert!")
  # alert.runModal
  #end

  private

  def start_indicator
    indicator.setHidden(false)
    indicator.startAnimation(self)
  end

  def stop_indicator
    indicator.setHidden(true)
    indicator.stopAnimation(self)
  end
end
