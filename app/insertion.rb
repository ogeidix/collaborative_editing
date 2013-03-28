###############################################################################
## Insertion
###############################################################################
## represents the Insertion change and inherits the behaviour from the Change class
## See change.rb for help
##

require_relative 'change'

module CollaborativeEditing
    class Insertion < Change

        attr_reader :content

        def initialize (author, position, new_content)
            super(author, position)
            @content = new_content
        end

        def new_position
            new_offset = @position.offset + @content.length
            return Position.new(@position.node, new_offset, @position.version+1)
        end

        def conflict?(positions, history)
            return false
        end

        def to_hash
            super({:content => @content})
        end

        def perform_transformation(other_position)
            new_offset = other_position.offset
            if other_position.node == @position.node
                if other_position.offset >= @position.offset
                    new_offset += @content.length
                end
            end
            return Position.new(other_position.node, new_offset, @version.to_i+1)
        end

        def perform_change(document)
            parent_node = REXML::XPath.first document.rexml_doc, @position.parent_node
            i = 0
            n = 0
            c = @position.child_number.to_i
            while (i < c) do
                i +=1 if(parent_node.children[n].class == REXML::Text)
                n += 1
            end
            current_node = parent_node.children[n-1]            
            prefix = current_node.value[0, @position.offset]
            suffix = current_node.value[@position.offset, current_node.value.length]
            current_node.value = prefix + @content + suffix
        end
    end
end
