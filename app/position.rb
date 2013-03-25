module CollaborativeEditing
    class Position

        attr_reader :node, :offset, :version

        def initialize(node, offset, version)
            @node = node
            @offset = offset
            @version = version
        end

        def == (another)
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
        
        def transform(history, up_to = Float::INFINITY)
            while (history[@version] != nil && @version < up_to) do
              # transform the position and increment the version
              change = history[@version]
              
              # TODO: this must be modified for deletion
              # currently works just ofr insertion
              if change.is_a? Insertion
                if @node == change.position.node
                  if @offset >= change.position.offset
                    @offset += change.content.length
                  end
                end
              elsif change.is_a? Deletion
                if @node == change.position.node
                  if (change.direction == 'left' && 
                      (change.position.offset <= @offset))
                      @offset -= change.length
                  elsif (change.direction == 'right' &&
                         (change.position.offset <= @offset))
                      @offset -= change.length
                  end
                end
              end
              @version += 1
            end
            
        end
    end
end
