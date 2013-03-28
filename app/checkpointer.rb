require "thread"

module CollaborativeEditing
    class Checkpointer

		CHECKPOINT_MESSAGE = "CHECKPOINT"

    	def initialize()
    		@scheduled = false
    		@mutex     = Mutex.new
			@resource  = ConditionVariable.new
			Application.logger.debug "[checkpointer] init"
			run()
    	end

    	def self.recovery(logfilename)
    		return true unless File.file?(logfilename)
    		last_checkpoint_lsn  = 0
    		logs = File.new(logfilename)
    		logs.each do |line|
    			if line.split(Logger::DELIMITER)[1].tr("\n","") == CHECKPOINT_MESSAGE
    				last_checkpoint_lsn = line.split(Logger::DELIMITER)[0].to_i
    			end
    		end
			logs.close

            files = {}            
            logs = File.new(logfilename)
            log_lsn = last_checkpoint_lsn
    		logs.each do |line|
    			splits = line.split(Logger::DELIMITER)
    			log_lsn  = splits[0].to_i

    			next if log_lsn <= last_checkpoint_lsn
                filename = splits[1]
                version  = splits[2]
                checksum = splits[3]
                author   = splits[4]
                node     = splits[5]
                offset   = splits[6]
                change   = splits[7]

                files[filename] ||= Document.new(filename.to_s)
                doc = files[filename]
                file_lsn = doc.rexml_doc[0][5].string.split[2].to_i

                if file_lsn.to_i < log_lsn.to_i
                  # apply the changes in the log
                  position = Position.new(node, offset.to_i, version.to_i)

                  if change == 'insertion'
                    content = splits[8]
                    logged_change = Insertion.new(author, position, content)
                  elsif change == 'deletion'
                    direction = splits[8]
                    length    = splits[9]
                    logged_change = Deletion.new(author, position, direction, length.to_i)
                  end

                  doc.execute_change(logged_change, false)
               end
    		end
    		logs.close

            # write all these updated documents to disk
            files.each_pair do |k,v|
              checksum = Digest::MD5.hexdigest(v.rexml_doc.to_s)
              v.update_master(checksum, 0, log_lsn.to_i)
            end

            # delete the old log file
            File.delete(logfilename)

            logs     = File.open(logfilename, "a")           
            logs.puts((log_lsn+1).to_s + Logger::DELIMITER + CHECKPOINT_MESSAGE)
            logs.close
    	end

    	def schedule!
    		Application.logger.info "[checkpointer] scheduled"
			@mutex.synchronize {
				@scheduled = true
				@resource.signal
			}
    	end

    	private
	   		def run
	   			Thread.new do
	   				Application.logger.info "[checkpointer] started"
	   			    while(true)
		   			  @mutex.synchronize {
	    				if !@scheduled
	    					Application.logger.info "[checkpointer] sleeping"
	    					@resource.wait(@mutex)
	    				end
	    				@scheduled = false
	  				  }
	  				  Application.logger.info "[checkpointer] woke up"
	  				  execute!
	  				end
	   			end
	   		end 	

	   		def execute!
                Room.rooms.each do |name, room|
                    checksum = Digest::MD5.hexdigest(room.document.rexml_doc.to_s)
                    room.document.update_master checksum
                end
                Application.logger.recovery CHECKPOINT_MESSAGE
                Document.reset_operations_since_checkpoint
	   		end
    end
end
