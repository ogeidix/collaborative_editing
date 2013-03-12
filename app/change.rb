module CollaborativeEditing
    class Change 

        attr_reader :username, :position, :change

        def initialize (author, position, new_change)
            @username = author
            @position = position
            @change = new_change
            @type = 'add'
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
