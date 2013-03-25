module CollaborativeEditing
    class Change

        attr_reader :username, :position

        def initialize (author, position)
            @username = author
            @position = position
        end

        def conflict?(position)
            throw "to implement in subclass"
        end

        def transform(history)
            @position.transform(history)
        end

        def new_position
            throw "to implement in subclass"
        end        	

        def to_hash
            throw "to implement in subclass"
        end
    end
end
