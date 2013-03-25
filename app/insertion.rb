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
            return Position.new(@position.node, new_offset, @position.version)
        end

        def conflict?(position)
            return false
        end

        def to_hash
            return ({:type => 'insert', :content => @content}).merge(@position.to_hash)
        end
    end
end
