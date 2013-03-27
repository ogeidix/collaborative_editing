###############################################################################
## Client
###############################################################################
## this class represent the client connected to the server,
## a new object is created for each connection.
##
## Client#join_room                 executed when a new connection is initialized
## Client#send_to_browser(message)  send the message to the browser through websocket
## Client#received_data(data)       executed when a message from the browser is received
##                                  it routes each message to the correct action
##

module CollaborativeEditing
  class Client < Cramp::Websocket

    before_start :join_room
    on_data      :received_data
    
    attr_reader :position, :username

    def join_room
      @filename = params[:document]
      @room     = Room.for(@filename)
      @room.subscribe self
    end

    def send_to_browser(message)
      render Yajl::Encoder.encode(message)
    end

    def received_data(data)
      Application.logger.debug("[client] received: " + data)
      msg = parse_json(data)

      case msg[:action]
        when 'join'
          @username = msg[:user]
          doc = @room.document
          send_to_browser action: 'loadfile', content: doc.rexml_doc, version: doc.version
          @room.join @username

        when 'message'
          @room.talk @username, msg[:message]
          send_to_browser action: 'lock', about: 'change', granted: true
          
        when 'insertion'
          position = Position.new(msg[:node], msg[:offset].to_i , msg[:version].to_i)
          change   = Insertion.new(@username, position, msg[:content])
          granted  = @room.request_change(self, change)
          @position = change.new_position if granted
          send_to_browser action: 'lock', about: 'insertion', granted: granted

        when 'deletion'
          position = Position.new(msg[:node], msg[:offset].to_i, msg[:version].to_i)
          change   = Deletion.new(@username, position, msg[:direction], msg[:length].to_i)
          granted = @room.request_change(self, change)
          @position = change.new_position if granted
          send_to_browser action: 'lock', about: 'deletion', granted: granted

        when 'relocate'
          new_position = Position.new(msg[:node], msg[:offset].to_i , msg[:version].to_i)
          granted = @room.request_relocate(@username, new_position)
          @position = new_position if granted
          send_to_browser action: 'lock', about: 'relocate', granted: granted

        when 'bye'
          @room.unsubscribe self

        else
          Application.logger.warning('[client] unknown message: ' + data)

        end
    end
    
    private
      def parse_json(str)
        str.gsub!("'","\\\\'")
        Yajl::Parser.parse(str, :symbolize_keys => true)
      end
  end
end
