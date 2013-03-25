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

      def conflict?(other_position)
        return false if other_position.node != @position.node
        if(@direction == "left")
          if(@position.offset > other_position.offset && 
               (@position.offset - @length) <= other_position.offset)
              return true
          end  
        elsif (@direction=="right")
          if(@position.offset < other_position.offset &&
               (@position.offset + @length) >= other_position.offset)
              return true
          end  
        end
        return false
      end

      def to_hash
          return ({:user => @username, :type => 'deletion', :direction => @direction, :length => @length}).merge(@position.to_hash)
      end

    end
end
