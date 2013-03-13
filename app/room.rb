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
        end

        def broadcast(message)
            @clients.each { |client| client.send_to_browser message }
        end

        def subscribe(client)
            @clients << client 
        end

        def unsubscribe(client)
            @clients.delete client
            broadcast :action => 'control', :user => @username, :message => 'left the room'
        end

        def talk(message)
            broadcast message
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
                return false if change.conflict? client.position
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

            # else 
            #             broadcast :action => 'control', :user => @username, :message => 'request change denied'
            return true
        end

        def request_relocate(username, position)
            if (@document.version != position.version)
                puts "relocate denied: wrong versin"
                return false 
            end
            @clients.each { |client| 
                if (client.position == position && client.username != username)
                    puts "relocate denied: conflic position"
                    return false
                end
            }
            return true
        end
    end
end
