###############################################################################
## Deletion
###############################################################################
## represents the Deletion change and inherits the behaviour from the Change class
## See change.rb for help
##


require_relative 'change'

module CollaborativeEditing
    class Deletion < Change

      attr_reader :direction, :length

      def initialize(author, position, direction, length)
        super(author, position)
        @direction = direction
        @length = length
      end

      def new_position
        if(@direction == "left")
          new_y =  @position.offset - @length  
        else
          new_y = @position.offset
        end
        return Position.new(@position.node, new_y, @position.version+1)
      end

      def conflict?(positions, history)
        return super(positions, history) do |other|
          next if other.node != @position.node
          if(@direction == "left" &&
               (@position.offset > other.offset) && 
                 (@position.offset - @length) <= other.offset)
                return true
          end
          if (@direction=="right" &&
                 (@position.offset < other.offset) &&
                   (@position.offset + @length) >= other.offset)
                return true
          end  
        end
      end

      def to_hash
        super({:direction => @direction, :length => @length})
      end

      def perform_transformation(other_position)
        new_offset = other_position.offset
        if other_position.node == change.position.node
          if (@direction == 'left' && (@position.offset <= new_offset))
              new_offset -= @length
          elsif (@direction == 'right' && (@position.offset <= new_offset))
              new_offset -= @length
          end
        end
        return Position.new(other_position.node, new_offset, @version)
      end

    end
end
