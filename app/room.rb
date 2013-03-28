module CollaborativeEditing
    class Room

        @@rooms = {}

        attr_reader :document

        def self.rooms
            @@rooms
        end

        def self.for(document)
            @@rooms[document] ||= Room.new(document)
        end

        def initialize(document)
            @document = Document.new(document)
            @clients  = []
            Application.logger.info format_log("room created")
        end

        def subscribe(client)
            @clients << client 
        end

        def unsubscribe(client)
            Application.logger.info format_log("#{client.username} left the file")
            @clients.delete client
            broadcast :action => 'control', :user => client.username, :message => 'left the room'
        end

        def join(username)
            Application.logger.info format_log("#{username} joined the file")
            broadcast :action => 'control', :user => username, :message => 'joined the file ' + document.filename
        end

        def talk(username, message)
            broadcast action: 'message', user: username, message: message
        end

        def request_change(client, change)
            Application.logger.debug format_log("request change - user: #{change.username} pos: #{change.position} change: #{change.type_of_change}")

            # transform the position to the current version
            change.transform(@document.history)
            client.position.transform(@document.history) if client.position

            # check coherent of position of client with server
            if (client.position != change.position)
                Application.logger.debug format_log("request change - user: #{change.username} status: denied reason: position incoherent client: #{client.position.to_s} change: #{change.position.to_s}")
                return false
            end

            # Check for conflict
            if change.conflict?(clients_positions(client.username), @document.history)
                Application.logger.debug format_log("request change - user: #{change.username} status: denied reason: conflict  change of: #{change.username} confilict with #{client.username}'s position #{client.position}")
                return false
            end

            Application.logger.debug format_log("request change - user: #{change.username} status: granted")
            @document.execute_change(change, true)
            broadcast change.to_hash

            return true
        end

        def request_relocate(username, position)
            Application.logger.debug format_log("request relocate - user: #{username} pos: #{position}")
            if (@document.version > position.version &&
                ! position.transform(@document.history, position.version))
                    not_exist = "Position does not exist in current document version"
                    Application.logger.debug format_log("request relocate - user: #{username} status: denied. " + not_exist)
                    return false
            end
            if position.conflict?(clients_positions(username), @document.history)
                Application.logger.debug format_log("request relocate - user: #{username} status: denied")
                return false 
            end
            Application.logger.debug format_log("request relocate - user: #{username} status: granted")
            return true
        end

        private
            def broadcast(message)
                Application.logger.debug format_log("broadcast: " + message.to_s)
                @clients.each { |client| client.send_to_browser message }
            end

            def format_log(message)
                return "[room] " + @document.filename.to_s + " v" + document.version.to_s + " - " + message
            end

            def clients_positions(except_username = nil)
                (@clients.reject { |c| c.position==nil || c.username==except_username }).map { |c| c.position }
            end
    end
end
