###############################################################################
## Insertion
###############################################################################
## represents the Insertion change and inherits the behaviour from the Change class
## See change.rb for help
##

require_relative 'change'

module CollaborativeEditing
    class Insertion < Change

        attr_reader :content

        def initialize (author, position, new_content)
            super(author, position)
            @content = new_content
        end

        def new_position
            new_offset = @position.offset + @content.length
            return Position.new(@position.node, new_offset, @position.version+1)
        end

        def conflict?(positions, history)
            return false
        end

        def to_hash
            super({:content => @content})
        end

        def perform_transformation(other_position)
            new_offset = other_position.offset
            if other_position.node == @position.node
                if other_position.offset >= @position.offset
                    new_offset += @content.length
                end
            end
            return Position.new(other_position.node, new_offset, @version+1)
        end

    end
end
