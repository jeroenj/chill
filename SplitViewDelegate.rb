class SplitViewDelegate

	attr_accessor :split_view
	
	MIN_SIZE = 200
	MAX_SIZE = 100 # height - this
	
	def	splitView(split_view, constrainMinCoordinate: proposed_coordinate, ofSubviewAt: index)
		proposed_coordinate + MIN_SIZE
	end
	
	def	splitView(split_view, constrainMaxCoordinate: proposed_coordinate, ofSubviewAt: index)
		proposed_coordinate - MAX_SIZE
	end
end
