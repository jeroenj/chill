class ChillDocument < NSPersistentDocument
  attr_accessor :request_url, :request_method, :output, :indicator, :request_headers, :headers_tab_view

  attr_accessor :engine

  def init
    if super
      @engine = Wrapper.new
      @engine.delegate = self
      self
    end
  end

  def awakeFromNib
    @http_headers = []
    @request_headers.dataSource = self
  end

  # Name of nib containing document window
  def windowNibName
    'ChillDocument'
  end

  # Document data representation for saving (return NSData)
  def dataOfType(type, error:outError)
    outError.assign(NSError.errorWithDomain(NSOSStatusErrorDomain, code:-4, userInfo:nil))
    nil
  end

  # Read document from data (return non-nil on success)
  def readFromData(data, ofType:type, error:outError)
    outError.assign(NSError.errorWithDomain(NSOSStatusErrorDomain, code:-4, userInfo:nil))
    nil
  end

  # Return lowercase 'untitled', to comply with HIG
  def displayName
    fileURL ? super : super.sub(/^[[:upper:]]/) {|s| s.downcase}
  end




  # TableView Actions
  def numberOfRowsInTableView(view)
    @http_headers.size
  end

  def tableView(view, objectValueForTableColumn:column, row:index)
    parameter = @http_headers[index]

    case column.identifier
    when 'name'  then parameter.name
    when 'value' then parameter.value
    end
  end

  def tableView(view, setObjectValue:object, forTableColumn:column, row:index)
    parameter = @http_headers[index]
    case column.identifier
    when 'name'  then parameter.name = object
    when 'value' then parameter.value = object
    end
  end




  # GUI Actions
  def rest_call(sender)
    url = NSURL.URLWithString(request_url.stringValue)
    verb = request_method.titleOfSelectedItem

    start_indicator
    output.string = ''

    @engine.sendRequestTo(url, usingVerb:verb, withParameters:request_parameters)
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
      show_response_tab
    end
  end

  def wrapperHasBadCredentials(wrapper)
    # handle this in here by showing an overlay in which you can enter your credentials
    stop_indicator
    alert = NSAlert.alertWithMessageText("Bad credentials!", defaultButton:"OK", alternateButton:nil, otherButton:nil, informativeTextWithFormat:"Please specify a valid username and password")
    alert.runModal
  end

  def wrapper(wrapper, didCreateResourceAtURL:url)
    stop_indicator
    alert = NSAlert.alertWithMessageText("Resource created at #{url}", defaultButton:"OK", alternateButton:nil, otherButton:nil, informativeTextWithFormat:"")
    alert.runModal
  end

  def wrapper(wrapper, didFailWithError:error)
    stop_indicator
    alert = NSAlert.alertWithError(error)
    alert.runModal
  end

  #def wrapper(wrapper, didReceiveStatusCode:statusCode)
  # stop_indicator
  # alert = NSAlert.alertWithMessageText("Status code not OK", defaultButton:"OK", alternateButton:nil, otherButton:nil, informativeTextWithFormat:"I am an alert!")
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

  def show_response_tab
    headers_tab_view.selectLastTabViewItem(self)
  end

  def request_parameters
    parameters = {}
    begin
      context = self.managedObjectContext

      all_parameters_request = NSFetchRequest.alloc.init
      all_parameters_request.entity = NSEntityDescription.entityForName('Parameter', inManagedObjectContext:context)

      error = nil
      array = context.executeFetchRequest(all_parameters_request, error:error)

      if array.size > 0
        array.each do |parameter|
          parameters[parameter.valueForKey('name')] = parameter.valueForKey('value') if parameter.valueForKey('name') && parameter.valueForKey('value')
        end
      else
        parameters = nil
      end
    rescue => e
      puts "Error while building parameters: #{e}"
    end
    parameters
  end
end
