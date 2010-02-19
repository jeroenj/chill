class SplitViewDelegate
  attr_accessor :split_view

  MIN_SIZE = 200
  MAX_SIZE = 148 # height - this

  def	splitView(sender, constrainMinCoordinate: proposed_coordinate, ofSubviewAt: index)
    proposed_coordinate + MIN_SIZE
  end

  def	splitView(sender, constrainMaxCoordinate: proposed_coordinate, ofSubviewAt: index)
    proposed_coordinate - MAX_SIZE
  end

  def splitView(sender, resizeSubviewsWithOldSize: old_size)
    top = sender.subviews.objectAtIndex(0)
    bottom = sender.subviews.objectAtIndex(1)

    new_frame = sender.frame
    top_frame = top.frame
    bottom_frame = bottom.frame

    divider_thickness = sender.dividerThickness

    top_frame.size.width = bottom_frame.size.width = new_frame.size.width

    bottom_frame.size.height = new_frame.size.height - top_frame.size.height - divider_thickness
    if bottom_frame.size.height < MAX_SIZE
      top_frame.size.height = top_frame.size.height - (MAX_SIZE - bottom_frame.size.height)
      bottom_frame.size.height = MAX_SIZE
    end

    bottom_frame.origin.y = top_frame.size.height + divider_thickness

    top.frame = top_frame
    bottom.frame = bottom_frame
  end
end
