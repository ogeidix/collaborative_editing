module CollaborativeEditing
    class Position

      attr_reader :node, :offset, :version

      def initialize(node, offset, version)
          @node = node
          @offset = offset
          @version = version
      end

      def == (another)
          return false unless another.is_a? Position
          return @node == another.node && @offset == another.offset && @version == another.version
      end
	
    	def parent_node
    	    @node.split('/')[0..-2].join('/')
    	end

    	def child_number
    	    @node.match( /text\[(\d+)?\]$/)[1]
    	end

      def to_hash
          return { :node => @node, :offset => @offset, :version => @version}
      end

      def to_s
          "(#{@node},#{@offset})@v#{@version}"
      end
        
      def conflict?(positions, history)
          positions.each { |other| 
              if other.version < self.version
                other = other.clone.transform(history, self.version)
              end
              return true if other == self
          }
          return false
      end

        def transform(history, up_to = Float::INFINITY)
            while (history[@version] != nil && @version < up_to) do
              change = history[@version]
        
              return false if change.conflict?(self, history)
              new_position = change.perform_transformation self

              @node    = new_position.node
              @offset  = new_position.offset
              @version = new_position.version
            end
            return self
        end
    end
end
