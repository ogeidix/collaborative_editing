module CollaborativeEditing
    class Document
        # This class represent the document
        # its purpose is to manage the content,
        # its changes and its history
        
        attr_reader :name, :version, :rexml_doc
        
        def initialize(name)
            # server maintains all files under $COLLAB_EDITOR_HOME/data/
            # if file exists, then send its contents, else create a new file with default content
            if !File.file?("data/" + name)
                # replicate the default file
                FileUtils.cp("app/default.file", "data/" + name) 
            end

            @rexml_doc = REXML::Document.new(File.new("data/" + name))          
            @name = name
            @version = 3
        end
	
        def execute_change(change)
            puts "Parent: #{change.position.parent_node} - Child Num. #{change.position.child_number}"
            parent_node = REXML::XPath.first @rexml_doc, change.position.parent_node
            i = 0
            n = 0
            c = change.position.child_number.to_i
            while (i < c) do
                i +=1 if(parent_node.children[n].class == REXML::Text)
                n += 1
            end
            current_node = parent_node.children[n-1]
            puts "Current node before: " + current_node.value
        end
    end
end
