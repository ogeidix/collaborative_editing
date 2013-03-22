module CollaborativeEditing
    class Room
        @@rooms = {}

        attr_reader :document

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
            Application.logger.debug format_log("request change - user: #{change.username} pos: #{change.position} change: #{change.change}")

            if (client.position != change.position)
                Application.logger.debug format_log("request change - user: #{change.username} status: denied reason: position incoherent")
                return false
            end
#
            # Check for conflict
            @clients.each { |client|
                next if client.username == change.username
                next if client.position.nil?
                if change.conflict? client.position
                    Application.logger.debug format_log("request change - user: #{change.username} status: denied reason: conflict")
                    return false
                end
            }

            @document.execute_change change
            h = {   action:  change.verb,
                    user:    change.username,
                    node:    change.position.node,
                    y:       change.position.y,
                    version: document.version 
                }
                      
            if change.verb.eql?('insert')
                h[:changes] = change.change
            elsif change.verb.eql?('delete') 
                h[:direction] = change.direction
                h[:length] = change.length
            end

            broadcast h     

            Application.logger.debug format_log("request change - user: #{change.username} status: granted")

            if @document.operations_since_checkpoint >= @document.UPDATE_FREQUENCY
              @document.reset_operations_since_checkpoint
              @@rooms.values.each do |room|
                  checksum = Digest::MD5.hexdigest(room.document.rexml_doc.to_s)
                  room.document.update_master checksum
              end
              Application.checkpointer.schedule!
            end
            return true
        end

        def request_relocate(username, position)
            Application.logger.debug format_log("request relocate - user: #{username} pos: #{position}")      
            if (@document.version != position.version or conflict_with_others(username, position))
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

            def conflict_with_others(username, position)
                @clients.each { |client| 
                    next        if client.username == username
                    return true if client.position == position
                }
                return false
            end
    end
end
