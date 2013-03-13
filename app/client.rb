module CollaborativeEditing
  class Client < Cramp::Websocket

    before_start :join_room
    on_finish    :leave_room
    on_data      :received_data
    attr_reader :position, :username

    def join_room
      @filename = params[:document]
      @room = Room.for(@filename)
      @room.subscribe self
    end
    
    def leave_room
      broadcast :action => 'control', :user => @username, :message => 'left the room'
    end

    def send_to_browser(message)
	  message = encode_json(message) if message.class != String
      render message
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
          broadcast msg.merge(:user => @username)
          
        when 'change'
          broadcast :action => 'control', :user => @username, :message => 'request change pos: ( ' + msg[:node] + ',' + msg[:y].to_s + '), @' + msg[:version].to_s + ':' + msg[:changes];
          
          position = Position.new(msg[:node], msg[:y].to_i , msg[:version].to_i)
          change = Change.new(@username, position, msg[:changes])

          if (@room.request_change change)
            broadcast :action => 'control', :user => @username, :message => 'request change granted'

            puts "in client: change is :" + msg[:changes]
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
            
            # broadcast to client to merge
            broadcast :action => 'change', :user => @username, :node => msg[:node], :y => msg[:y], :version => @room.document.version, :changes => msg[:changes] 
          else
            broadcast :action => 'control', :user => @username, :message => 'request change denied'
          end
        when 'relocate'
          broadcast :action => 'control', :user => @username, :message => 'request relocate pos: ( ' + msg[:node] + ',' + msg[:y].to_s + '), @' + msg[:version].to_s;
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
	    str.gsub!("'","\\\\'")
        Yajl::Parser.parse(str, :symbolize_keys => true)
      end
  end
end
