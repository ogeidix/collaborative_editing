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
          send_to_browser action: 'loadfile',
                          content: @room.document.rexml_doc,
                          version: @room.document.version
          @room.join @username

        when 'message'
          @room.talk @username, msg[:message]
          
        when 'change'
          position = Position.new(msg[:node], msg[:y].to_i , msg[:version].to_i)
          change   = Change.new(@username, position, msg[:changes])
          if @room.request_change(self, change)
            @position = change.new_position(@room.document.version)
          else
            if change.deletion?
              send_to_browser action: 'lock', about: 'change', granted: false
            end
          end
            
        when 'relocate'
          new_position = Position.new(msg[:node], msg[:y].to_i , msg[:version].to_i)
          if (@room.request_relocate @username, new_position)
            @position = new_position  
            send_to_browser action: 'lock', about: 'relocate', granted: true
          else
            send_to_browser action: 'lock', about: 'relocate', granted: false
          end

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
