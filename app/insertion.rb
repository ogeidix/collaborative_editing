module CollaborativeEditing
    class Insertion 

        attr_reader :username, :position, :content, :verb

        def initialize (author, position, new_content)
            @username = author
            @position = position
            @content = new_content
            @verb = 'insert'
        end

        def new_position(document_version)
            new_y = @position.y + @content.length
            return Position.new(@position.node, new_y, document_version)
        end

        def deletion?
            @content[0].ord == 8
        end

        def conflict?(position)
            return true if @position == position
			# IF the versions dont match, then we need to bring them to the same version 
			# and then compare them

            # if content is APPEND
            #    return false
            # if content is DELETE
            #    y = content,position.y- content.size 
            #    ....
            return false
        end

        def transform(history)
            # find the version parent of the history
            # apply to the end
            @position.transform(history)
            return true
        end

        def to_hash
            return { :user => @username, :position => position.to_hash, :type => @verb, :content => @content}
        end
    end
end
