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

        def join(username)
            Application.logger.info format_log("#{username} joined the file")
            broadcast :action => 'control', :user => username, :message => 'joined the file ' + document.name
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
            broadcast :action => 'control', :user => username, :message => 'request relocate pos: ( ' + position.node + ',' + position.y.to_s + '), @' + position.version.to_s;
            if (@document.version != position.version)
                broadcast :action => 'lock', :user => username, :when => 'relocate', :granted => false
                broadcast :action => 'control', :user => username, :message => 'request relocate denied'
                return false 
            end
            @clients.each { |client| 
                if (client.position == position && client.username != username)
                    broadcast :action => 'lock', :user => username, :when => 'relocate', :granted => false
                    broadcast :action => 'control', :user => username, :message => 'request relocate denied'
                    return false
                end
            }
            broadcast :action => 'control', :user => username, :message => 'request relocate granted'
            broadcast :action => 'lock', :user => username, :when => 'relocate', :granted => true
            return true
        end

        def format_log(message)
            return @document.name.to_s + " v" + document.version.to_s + " - " + message
        end
    end
end
