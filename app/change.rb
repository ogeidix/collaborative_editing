###############################################################################
## Change
###############################################################################
## this is the SUPER class of all the changes
##
## Change#transform(history)     change the object to be update with the history
## Change#new_position           return a new object Position which is the user position after the change
## Change#to_hash                return the attributes as hash, useful for JSON. will merge the input hash
## Change#type_of_change         return the name of the change. It is extracted from the name of the class
## Change#conflict               check the change agains ONE or AN ARRAY of lock positions.
##                               !! receive in input A BLOCK OF CODE to perform the check against one position
## Change#perform_transformation return a new Position object which is the input position after this change
## Change#perform_change         actually change the content of the document which is exposed in the rexml_doc attribute
##

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

        def perform_transformation(position)
            throw "to implement in subclass"
        end

        def perform_change(document)
            throw "to implement in subclass"
        end

    end
end
