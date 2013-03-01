module CollaborativeEditing
    class Change 

        attr_reader :username, :position, :changes

        def initialize (author, position, changes)
            @username = author
            @position = position
            @changes = changes
        end

        def conflict?(position)
            return true if @position == position
			# IF the versions dont match, then we need to bring them to the same version 
			# and then compare them

            # if change is APPEND
            #    return false
            # if change is DELETE
            #    y = change,position.y- change.size 
            #    ....
            return false
        end
    end
end
