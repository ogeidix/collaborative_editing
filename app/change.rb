module CollaborativeEditing
    class Change

        attr_reader :username, :position

        def initialize (author, position)
            @username = author
            @position = position
        end

        def conflict?(positions, history)
            positions = ([] << positions).flatten
            positions.each { |other|
                if (other.version < @position.version)
                    other = other.clone.transform(history, @position.version)
                end
                yield other
            }
            return false
        end

        def transform(history)
            @position.transform(history)
        end

        def new_position
            throw "to implement in subclass"
        end        	

        def to_hash(to_be_merged)
            ({:user => @username, :action => type_of_change}).merge(@position.to_hash).merge(to_be_merged)
        end
        
        def type_of_change
          return self.class.to_s.downcase.split('::').last
        end
    end
end
