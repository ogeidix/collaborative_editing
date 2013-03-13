module CollaborativeEditing
    class Change 

        attr_reader :username, :position, :change

        def initialize (author, position, new_change)
            @username = author
            @position = position
            @change = new_change
            @type = 'add'
        end

        def new_position(document_version)
            new_y = @position.y + @change.length
            return Position.new(position.node, new_y, document_version)
        end

        def deletion?
            @change[0].ord == 8
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

        def to_hash
            return { :user => @username, :position => position.to_hash, :type => @type, :content => @change}
        end
    end
end
