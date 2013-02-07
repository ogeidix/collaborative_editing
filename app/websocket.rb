module CollaborativeEditing
  class Websocket < Cramp::Websocket

    before_start :join_room
    on_finish    :leave_room
    on_data      :received_data

    def join_room
      @room = Room.for(params[:document])
      @room.subscribe{|channel, message| render(message) }
    end
      
    def leave_room
      publish :action => 'control', :user => @user, :message => 'left the room'
    end

    def received_data(data)
      msg = parse_json(data)
      case msg[:action]
        when 'join'
          @user = msg[:user]
          publish :action => 'control', :user => @user, :message => 'joined the file ' + params[:document]
        when 'message'
          publish msg.merge(:user => @user)
        when 'move'
          # ...
        when 'change'
          # ...
      end
    end
    
    private
      def publish(message)
        @room.publish('chat', encode_json(message))
      end
      
      def encode_json(obj)
        Yajl::Encoder.encode(obj)
      end
      
      def parse_json(str)
        Yajl::Parser.parse(str, :symbolize_keys => true)
      end
  end
end