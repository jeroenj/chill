class ChillDocument < NSPersistentDocument
  attr_accessor :request_url, :request_method, :output, :indicator, :headers_tab_view, :authentication_sheet, :chill_window, :authtentication_button, :http_username, :http_password

  def init
    if super
      @engine = HTTPWrapper.instance
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
      when 'http_username'  then http_username.stringValue = obj.value
      when 'http_password'  then http_password.stringValue = obj.value
      end
    end

    refresh_lock
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
    start_indicator
    output.string = ''
    clear_response_parameters

    @engine.send_request_to(request_url.stringValue, {:verb => request_method.titleOfSelectedItem, :parameters => request_body, :headers => request_headers})
  end

  def controlTextDidEndEditing(notification)
    find_or_create_interface_object('request_url', request_url.stringValue)
  end

  def request_method_changed(sender)
    find_or_create_interface_object('request_method', request_method.titleOfSelectedItem)
  end




  # Authentication sheet
  def show_authentication_sheet(sender)
    NSApp.beginSheet(authentication_sheet, modalForWindow:chill_window, modalDelegate:self, didEndSelector:"authentication_sheet_did_end", contextInfo:nil)
  end

  def accept_authentication(sender)
    NSApp.endSheet(authentication_sheet)
    @engine.username = http_username.stringValue
    @engine.password = http_password.stringValue
    find_or_create_interface_object('http_username', http_username.stringValue)
    find_or_create_interface_object('http_password', http_password.stringValue)
    rest_call(nil)
  end

  def cancel_authentication(sender)
    NSApp.endSheet(authentication_sheet)
  end

  def authentication_sheet_did_end
    authentication_sheet.orderOut(self)
    refresh_lock
  end




  # HTTPWrapper Delegates
  def did_receive_data(data, with_response:response)
    headers = response.allHeaderFields

    headers.each_pair do |key, value|
      parameter = NSEntityDescription.insertNewObjectForEntityForName("Parameter", inManagedObjectContext:@context)
      parameter.name = key
      parameter.value = value
      parameter.kind = 'response'
    end

    text = NSString.alloc.initWithData(data, encoding:NSUTF8StringEncoding)

    if text
      output.string = text
      stop_indicator
      show_response_tab
    end

    find_or_create_interface_object('output', text)
  end

  def did_receive_authentication_challenge
    stop_indicator
    show_authentication_sheet(nil)
  end

  def did_fail_with_error(error)
    # -1012 is bad credentials
    unless error.code == -1012
      stop_indicator
      alert = NSAlert.alertWithError(error)
      alert.runModal
    end
  end

  private

  def start_indicator
    indicator.setHidden(false)
    indicator.startAnimation(self)
  end

  def stop_indicator
    indicator.setHidden(true)
    indicator.stopAnimation(self)
  end

  def refresh_lock
    if http_username.stringValue.empty? && http_password.stringValue.empty?
      authtentication_button.setImage(NSImage.imageNamed("NSLockUnlockedTemplate"))
    else
      authtentication_button.setImage(NSImage.imageNamed("NSLockLockedTemplate"))
    end
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

  def request_body
    data = {}
    begin
      request_body_request = NSFetchRequest.new
      request_body_request.entity = NSEntityDescription.entityForName('DataObject', inManagedObjectContext:@context)
      # request_body_request.predicate = NSPredicate.predicateWithFormat("(name != NIL) AND (value != NIL)")

      error = nil
      body_objects = @context.executeFetchRequest(request_body_request, error:error)

      if body_objects.size > 0
        body_objects.each do |body_object|
          data[body_object.name] = body_object.value if body_object.name && body_object.value # Filtering should be done with NSPredicate
        end
      else
        data = nil
      end
    rescue => e
      puts "Error while building request body: #{e}"
    end
    data
  end
  
  def request_headers
    data = {}
    begin
      request_headers_request = NSFetchRequest.new
      request_headers_request.entity = NSEntityDescription.entityForName('Parameter', inManagedObjectContext:@context)
      # request_headers_request.predicate = NSPredicate.predicateWithFormat("(name != NIL) AND (value != NIL)")

      error = nil
      header_objects = @context.executeFetchRequest(request_headers_request, error:error)

      if header_objects.size > 0
        header_objects.each do |header_object|
          data[header_object.name] = header_object.value if header_object.name && header_object.value # Filtering should be done with NSPredicate
        end
      else
        data = nil
      end
    rescue => e
      puts "Error while building request headers: #{e}"
    end
    data
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
