module CollaborativeEditing
    class Position

        attr_reader :node, :y, :version

        def initialize(node, y, version)
            @node = node
            @y = y
            @version = version
        end

        def == (another)
            return @node == another.node && @y == another.y && @version == another.version
        end
	
    	def parent_node
    	    @node.split('/')[0..-2].join('/')
    	end

    	def child_number
    	    @node.match( /text\[(\d+)?\]$/)[1]
    	end

        def to_hash
            return { :node => @node, :offset => @y, :version => @version}
        end

        def to_s
            "(#{@node},#{@y})@v#{@version}"
        end
    end
end
