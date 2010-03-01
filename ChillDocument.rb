class ChillDocument < NSPersistentDocument
  attr_accessor :request_url, :request_method, :output, :indicator, :headers_tab_view

  attr_accessor :engine, :context

  def init
    if super
      @engine = Wrapper.new
      @engine.delegate = self
      @context = self.managedObjectContext
      self
    end
  end

  def awakeFromNib
    all_interface_objects_request = NSFetchRequest.new
    all_interface_objects_request.entity = NSEntityDescription.entityForName('InterfaceObject', inManagedObjectContext:@context)

    error = nil
    interface_objects = @context.executeFetchRequest(all_interface_objects_request, error:error)

    interface_objects.each do |obj|
      case obj.name
      when 'request_url'    then request_url.stringValue = obj.value
      when 'output'         then output.string = obj.value
      when 'request_method' then request_method.selectItemWithTitle(obj.value)
      end
    end
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




  # GUI Actions
  def rest_call(sender)
    url = NSURL.URLWithString(request_url.stringValue)
    verb = request_method.titleOfSelectedItem

    start_indicator
    output.string = ''
    clear_response_parameters

    @engine.sendRequestTo(url, usingVerb:verb, withParameters:request_parameters)
  end

  def controlTextDidEndEditing(notification)
    find_or_create_interface_object('request_url', request_url.stringValue)
  end

  def request_method_changed(sender)
    find_or_create_interface_object('request_method', request_method.titleOfSelectedItem)
  end




  # REST Wrapper Delegates
  def wrapper(engine, didRetrieveData:data)
    response = engine.httpResponse
    headers = response.allHeaderFields

    headers.each_pair do |key, value|
      parameter = NSEntityDescription.insertNewObjectForEntityForName("Parameter", inManagedObjectContext:@context)
      parameter.name = key
      parameter.value = value
      parameter.kind = 'response'
    end

    text = engine.responseAsText

    if text
      output.string = text
      stop_indicator
      show_response_tab
    end

    find_or_create_interface_object('output', text)
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

  def clear_response_parameters
    response_parameters_request = NSFetchRequest.new
    response_parameters_request.entity = NSEntityDescription.entityForName('Parameter', inManagedObjectContext:@context)
    response_parameters_request.predicate = NSPredicate.predicateWithFormat("%K LIKE %@", 'kind', 'response')

    error = nil
    parameters = @context.executeFetchRequest(response_parameters_request, error:error)

    parameters.each do |parameter|
      @context.deleteObject(parameter)
    end
  end

  def request_parameters
    parameters = {}
    begin
      request_parameters_request = NSFetchRequest.new
      request_parameters_request.entity = NSEntityDescription.entityForName('Parameter', inManagedObjectContext:@context)
      request_parameters_request.predicate = NSPredicate.predicateWithFormat("%K LIKE %@ AND name != NIL AND value != NIL", 'kind', 'request')

      error = nil
      request_parameters = @context.executeFetchRequest(request_parameters_request, error:error)

      if request_parameters.size > 0
        request_parameters.each do |parameter|
          parameters[parameter.name] = parameter.value
        end
      else
        parameters = nil
      end
    rescue => e
      puts "Error while building parameters: #{e}"
    end
    parameters
  end
  
  def find_or_create_interface_object(name, value)
    interface_objects_request = NSFetchRequest.new
    interface_objects_request.entity = NSEntityDescription.entityForName('InterfaceObject', inManagedObjectContext:@context)
    interface_objects_request.predicate = NSPredicate.predicateWithFormat("%K LIKE %@", 'name', name)

    error = nil
    interface_objects = @context.executeFetchRequest(interface_objects_request, error:error)

    case interface_objects.size
    when 0
      interface_object = NSEntityDescription.insertNewObjectForEntityForName("InterfaceObject", inManagedObjectContext:@context)
      interface_object.name = name
      interface_object.value = value
    else
      interface_objects.each do |obj|
        @context.deleteObject(obj)
      end
      find_or_create_interface_object(name, value)
    end
  end
end
