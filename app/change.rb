module CollaborativeEditing
    class Change 

        attr_reader :username, :position, :changes

        def initialize (author, position, changes)
            @username = author
            @position = position
            @changes = changes
        end

        def conflict?(position)
            return false if @position.node ! position.node
            # if change is APPEND
            #    return false
            # if change is DELETE
            #    y = change,position.y- change.size 
            #    ....
            return true
        end
    end
end
