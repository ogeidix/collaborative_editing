module CollaborativeEditing
	class Room
		@@rooms = {}

		def self.for(document)
			@@rooms[document] ||= Room.new(document)
		end

		def initialize(document)
			@document  = Document.new(document)
			@clients = []
		end

		def broadcast(message)
			@clients.each { |client| client.send_to_browser(message) }
		end

		def subscribe(client)
			@clients << client 
		end

        def request_change( change)
            # FOR NOW DO NOT TRANSLATE position in current version
            # if check position is == to client position
            # 
            # ALGORITHM:
            # - check for conflict
            @clients.each { |client|
                next if client.username == change.username
                return false if change.conflict? client.position
            }

            # - prepare change -> merge inside document
            # - commit change
            return true
        end

        def request_relocate( username, position)
            return false if (@document.version != position.version)
            @clients.each { |client| 
             return false if (client.position == position && client.username != username)
            }
            return true
        end
	end
end
