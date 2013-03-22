module CollaborativeEditing
    class Change 

        attr_reader :username, :position, :change

        def initialize (author, position, new_change)
            @username = author
            @position = position
            @change = new_change
            @type = 'add'
            if deletion? 
                @type = 'del'
            end
        end

        def new_position(document_version)
            if deletion?
                new_y = @position.y - @change.length
                # if is zero 
                # check delete node
                # at now, we can not delete the node, 
                # make it jump to the previous node
                # still a lot of work. 
                if new_y < 0
                    new_y =0
                end
            else
                new_y = @position.y + @change.length
            end
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
            if deletion?
                Application.logger.debug format_log("change.delete conflict")
                nextpos = new_position(position.version)
                return true if nextpos == position
            end
            return false
        end

        def to_hash
            return { :user => @username, :position => position.to_hash, :type => @type, :content => @change}
        end
    end
end
