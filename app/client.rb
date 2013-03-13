module CollaborativeEditing
  class Client < Cramp::Websocket

    before_start :join_room
    on_finish    :leave_room
    on_data      :received_data
    
    attr_reader :position, :username

    def join_room
      @filename = params[:document]
      @room     = Room.for(@filename)
      @room.subscribe self
    end
    
    def leave_room
      @room.unsubscribe self
    end

    def send_to_browser(message)
      render Yajl::Encoder.encode(message)
    end

    def received_data(data)
      Application.logger.debug("received: " + data)
      msg = parse_json(data)

      case msg[:action]
        when 'join'
          @username       = msg[:user]          
          content         = @room.document.rexml_doc
          send_to_browser :action => 'loadfile', :content => content, :version => @room.document.version
          @room.join      @username

        when 'message'
          @room.talk msg.merge(:user => @username)
          
        when 'change'
          position = Position.new(msg[:node], msg[:y].to_i , msg[:version].to_i)
          change   = Change.new(@username, position, msg[:changes])
          @room.request_change change
            
        when 'relocate'
          new_position = Position.new(msg[:node], msg[:y].to_i , msg[:version].to_i)
          if (@room.request_relocate @username, new_position)
            @position = new_position  
          end

        end
    end
    
    private
      def parse_json(str)
        str.gsub!("'","\\\\'")
        Yajl::Parser.parse(str, :symbolize_keys => true)
      end
  end
end
