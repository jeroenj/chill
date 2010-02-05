#
# MyDocument.rb
# Chill
#
# Created by Jeroen Jacobs on 05/02/10.
# Copyright redstorm 2010. All rights reserved.
#

class ChillDocument < NSDocument
	
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

end
