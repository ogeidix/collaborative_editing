require_relative 'insertion'

module CollaborativeEditing
    class Deletion < Insertion

      attr_reader :direction, :length

      def initialize(author, position, direction, length)
        @username = author
        @position = position
        @direction = direction
        @length = length
        @verb = 'delete'
      end

      def new_position(document_version)
        new_y = @direction.eql?('left') ? @position.y - @length : @position.y
        return Position.new(@position.node, new_y, document_version)
      end

    end
end
