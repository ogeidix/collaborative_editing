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
	
	def parent_node
	    @node.split('/')[0..-2].join('/')
	end

	def child_number
	    @node.match( /text\[(\d+)?\]$/)[1]
	end
    end
end
