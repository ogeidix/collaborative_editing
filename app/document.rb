module CollaborativeEditing
    class Document
        # This class represent the document
        # its purpose is to manage the content,
        # its changes and its history
        
        attr_reader :name, :version, :rexml_doc
        
        def initialize(name)
            @name = name
            # HACK to be deleted later
            @version = 1        
            
            # server maintains all files under $COLLAB_EDITOR_HOME/data/
            # if file exists, then send its contents, else create a new file with default content
            if !File.file?("data/" + name) # + ".ver." + @version.to_s)
                # replicate the default file
                FileUtils.cp("app/default.file", "data/" + name) # + ".ver." + @version.to_s) 
            end
            @rexml_doc = REXML::Document.new(File.new("data/" + name)) # + ".ver." + @version.to_s))          
        end
    
        def execute_change(this_change)
            puts "Parent: #{this_change.position.parent_node} - Child Num. #{this_change.position.child_number}"
            parent_node = REXML::XPath.first @rexml_doc, this_change.position.parent_node
            i = 0
            n = 0
            c = this_change.position.child_number.to_i
            while (i < c) do
                i +=1 if(parent_node.children[n].class == REXML::Text)
                n += 1
            end
            current_node = parent_node.children[n-1]
            if  this_change.change[0].ord == 8
                puts "delete"
                this_length = this_change.change.length
                current_node.value = current_node.value[0, this_change.position.y - this_length] +current_node.value[this_change.position.y, current_node.value.length]
            else
                current_node.value = current_node.value[0, this_change.position.y] + this_change.change.to_s + current_node.value[this_change.position.y, current_node.value.length]
            end
                puts "Changed node : " + current_node.value
                #print @rexml_doc
                @version += 1
                # File.open("data/" + name + ".ver." + @version.to_s, 'w') {|f| f.write(@rexml_doc) }
                puts "version changed to " + @version.to_s
        end
    end
end
