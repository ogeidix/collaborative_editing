module CollaborativeEditing
    class Room
        @@rooms = {}

        attr_reader :document

        def self.for(document)
            @@rooms[document] ||= Room.new(document)
        end

        def initialize(document)
            @document  = Document.new(document)
            @clients = []
            @changes = []
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
            broadcast :action => 'control', :user => username, :message => 'joined the file ' + document.name
        end

        def talk(username, message)
            broadcast action: 'message', user: username, message: message
        end

        def request_change(change)
            broadcast :action => 'control', :user => change.username, :message => 'request change pos: ( ' + change.position.node + ',' + change.position.y.to_s + '), @' + change.position.version.to_s + ':' + change.change;
            # FOR NOW DO NOT TRANSLATE position in current version
            # if check position is == to client position
            # 
            # ALGORITHM:
            # - check for conflict
            @clients.each { |client|
                next if client.username == change.username
                next if client.position.nil?
                if change.conflict? client.position 
                    broadcast :action => 'lock', :user => change.username, :when => 'change', :granted => false
                    return false 
                end
            }

            @document.execute_change change
            @changes.push change
            # - prepare change -> merge inside document
            # - commit change
            # - add the change to @changes so that the version translation code 
            # can use it
            #

            broadcast :action => 'control', :user => change.username, :message => 'request change granted'
            broadcast :action => 'change', :user => change.username, :node => change.position.node, :y => change.position.y, :version => document.version, :changes => change.change
            broadcast :action => 'lock', :user => change.username, :when => 'change', :granted => true

            # else 
            #   broadcast :action => 'control', :user => @username, :message => 'request change denied'
            return true
        end

        def request_relocate(username, position)
            Application.logger.debug format_log("request relocate - user: #{username} pos: #{position}")
            if (@document.version != position.version or new_position_conflict_with_others(username, position))
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
                return "[room] " + @document.name.to_s + " v" + document.version.to_s + " - " + message
            end

            def new_position_conflict_with_others(username, position)
                @clients.each { |client| 
                    next         if client.username == username
                    return true if client.position == position
                }
                return false
            end
    end
end
