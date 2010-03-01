class ChillDocument < NSPersistentDocument
  attr_accessor :request_url, :request_method, :output, :indicator, :headers_tab_view

  attr_accessor :engine

  def init
    if super
      @engine = Wrapper.new
      @engine.delegate = self
      self
    end
  end

  def awakeFromNib
    context = self.managedObjectContext

    all_interface_objects_request = NSFetchRequest.new
    all_interface_objects_request.entity = NSEntityDescription.entityForName('InterfaceObject', inManagedObjectContext:context)

    error = nil
    array = context.executeFetchRequest(all_interface_objects_request, error:error)

    array.each do |obj|
      request_url.stringValue = obj.valueForKey('value') if obj.valueForKey('name') == 'request_url'
      output.string = obj.valueForKey('value') if obj.valueForKey('name') == 'output'
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




  # REST Wrapper Delegates
  def wrapper(engine, didRetrieveData:data)
    response = engine.httpResponse
    headers = response.allHeaderFields

    headers.each_pair do |key, value|
      parameter = NSEntityDescription.insertNewObjectForEntityForName("Parameter", inManagedObjectContext:self.managedObjectContext)
      parameter.setValue(key, forKey:'name')
      parameter.setValue(value, forKey:'value')
      parameter.setValue('response', forKey:'kind')
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
    context = self.managedObjectContext

    response_parameters_request = NSFetchRequest.new
    response_parameters_request.entity = NSEntityDescription.entityForName('Parameter', inManagedObjectContext:context)
    response_parameters_request.predicate = NSPredicate.predicateWithFormat("%K LIKE %@", 'kind', 'response', 'name', 'value')

    error = nil
    array = context.executeFetchRequest(response_parameters_request, error:error)

    if array.size > 0
      array.each do |parameter|
        context.deleteObject(parameter)
      end
    else
      parameters = nil
    end
  end

  def request_parameters
    parameters = {}
    begin
      context = self.managedObjectContext

      request_parameters_request = NSFetchRequest.new
      request_parameters_request.entity = NSEntityDescription.entityForName('Parameter', inManagedObjectContext:context)
      request_parameters_request.predicate = NSPredicate.predicateWithFormat("%K LIKE %@ AND %K != NIL AND %K != NIL", 'kind', 'request', 'name', 'value')

      error = nil
      array = context.executeFetchRequest(request_parameters_request, error:error)

      if array.size > 0
        array.each do |parameter|
          parameters[parameter.valueForKey('name')] = parameter.valueForKey('value')
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
    context = self.managedObjectContext

    interface_objects_request = NSFetchRequest.new
    interface_objects_request.entity = NSEntityDescription.entityForName('InterfaceObject', inManagedObjectContext:context)
    interface_objects_request.predicate = NSPredicate.predicateWithFormat("%K LIKE %@", 'name', name)

    error = nil
    interface_objects = context.executeFetchRequest(interface_objects_request, error:error)

    case interface_objects.size
    when 0
      interface_object = NSEntityDescription.insertNewObjectForEntityForName("InterfaceObject", inManagedObjectContext:context)
      interface_object.setValue(name, forKey:'name')
      interface_object.setValue(value, forKey:'value')
    else
      interface_objects.each do |obj|
        context.deleteObject(obj)
      end
      find_or_create_interface_object(name, value)
    end
  end
end
