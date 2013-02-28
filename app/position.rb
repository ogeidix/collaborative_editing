module CollaborativeEditing
    class Position

        attr_reader :node, :y, :version

        def initialize(node, y, version)
            @node = node
            @y = y
            @version = version
        end

        def == (another)
            return @node == node && @y == y && @version == version
        end
    end
end
