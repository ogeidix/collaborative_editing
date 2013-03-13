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
      msg = parse_json(data)
      case msg[:action]
        when 'join'
          # send the file to the new participant.
          @username = msg[:user]          
          content = @room.document.rexml_doc

          # log this activity
          Application.logger.log Time.now.to_s + " !$! " \
                + @filename.to_s + " !$! " \
                + @room.document.version.to_s + " !$! " \
                + Digest::MD5.hexdigest(content.to_s) + " !$! " \
                + "join_file !$! " \
                + @username.to_s

          # send the file contents to the new participant
          send_to_browser :action => 'loadfile', :content => content, :version => @room.document.version

          # Broadcast a message to all participants indicating the new member
          broadcast :action => 'control', :user => @username, :message => 'joined the file ' + params[:document]
        when 'message'
          @room.talk msg.merge(:user => @username)
          
        when 'change'
          position = Position.new(msg[:node], msg[:y].to_i , msg[:version].to_i)
          change   = Change.new(@username, position, msg[:changes])
          @room.request_change change

            # log this change for recovery purpose
            Application.logger.log Time.now.to_s + " !$! " \
                + @filename.to_s + " !$! " \
                + @room.document.version.to_s + " !$! " \
                + Digest::MD5.hexdigest(@room.document.rexml_doc.to_s) + " !$! " \
                + "change_file !$! " \
                + @username.to_s + " !$! " \
                + msg[:node].to_s + " !$! " \
                + msg[:y].to_s + " !$! " \
                + @room.document.version.to_s 
                #+ " !$! " + msg[:changes]
            
        when 'relocate'
          new_position = Position.new(msg[:node], msg[:y].to_i , msg[:version].to_i)
          if (@room.request_relocate @username, new_position)
            @position = new_position  
          end

        end
    end
    
    private
      def broadcast(message)
        @room.broadcast(message)
      end
      
      def encode_json(obj)
        Yajl::Encoder.encode(obj)
      end
      
      def parse_json(str)
	    str.gsub!("'","\\\\'")
        Yajl::Parser.parse(str, :symbolize_keys => true)
      end
  end
end
