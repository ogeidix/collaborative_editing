module CollaborativeEditing
  class Websocket < Cramp::Websocket

    before_start :join_room
    on_finish    :leave_room
    on_data      :received_data

    attr_reader :position, :username

    def join_room
      @room = Room.for(params[:document])
      @room.subscribe self
    end
    
    def leave_room
      broadcast :action => 'control', :user => @username, :message => 'left the room'
    end

    def send_to_browser(message)
        render message
    end

    def received_data(data)
      msg = parse_json(data)
      case msg[:action]
        when 'join'
          @username = msg[:user]
          broadcast :action => 'control', :user => @username, :message => 'joined the file ' + params[:document]
        when 'message'
          broadcast msg.merge(:user => @username)
        when 'move'
          # ...
        when 'change'

          broadcast :action => 'control', :user => @username, :message => 'request change pos: ( ' + msg[:node] + ',' + msg[:y] + '), @' + msg[:version] + ':' + msg[:changes];
          
          position = Position.new(msg[:node], msg[:y].to_i , msg[:version].to_i)
          change = Change.new(@username, position, msg[:changes])
          if (@room.request_change change)
            broadcast :action => 'control', :user => @username, :message => 'request change granted'
          else
            broadcast :action => 'control', :user => @username, :message => 'request change denied'
          end
        when 'relocate'
          broadcast :action => 'control', :user => @username, :message => 'request relocate pos: ( ' + msg[:node] + ',' + msg[:y] + '), @' + msg[:version];
          new_position = Position.new(msg[:node], msg[:y].to_i , msg[:version].to_i)
          if (@room.request_relocate @username, new_position)
            @position = new_position  
            broadcast :action => 'control', :user => @username, :message => 'request relocate granted'
          else
            broadcast :action => 'control', :user => @username, :message => 'request relocate denied'
          end
        end
    end
    
    private
      def broadcast(message)
        @room.broadcast(encode_json(message))
      end
      
      def encode_json(obj)
        Yajl::Encoder.encode(obj)
      end
      
      def parse_json(str)
        Yajl::Parser.parse(str, :symbolize_keys => true)
      end
  end
end
