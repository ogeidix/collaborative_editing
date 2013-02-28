module CollaborativeEditing
	class Document
		# This class represent the document
		# its purpose is to manage the content,
		# its changes and its history
        
        attr_reader :name, :version
        
		def initialize(name)
			@name = name
            @version = 3
		end
	end
end
