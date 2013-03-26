module CollaborativeEditing
    class Logger

      # foreground color
      BLACK   = "\033[30m"
      RED     = "\033[31m"
      GREEN   = "\033[32m"
      BROWN   = "\033[33m"
      BLUE    = "\033[34m"
      MAGENTA = "\033[35m"
      CYAN    = "\033[36m"
      GRAY    = "\033[37m"

      # ANSI control chars
      RESET_COLORS   = "\033[0m"
      BOLD_ON        = "\033[1m"
      BOLD_OFF       = "\033[22m"
      BLINK_ON       = "\033[5m"
      BLINK_OFF      = "\033[25m"
    
      attr_reader :lsn, :DELIMITER, :logfilename
      
    	def initialize(logfile_name, levels)
    	   @logfilename = logfile_name
         @file_mutex  = Mutex.new
         @levels      = levels
         @DELIMITER   = " !!! "
         @lsn = 0
         
         if File.file?(@logfilename)
            @lsn = %x{wc -l < "#{@logfilename}"}.to_i

            # get the point where the last checkpoint was written
            sizeOfLogfile = %x{wc -l "app/collabedit.log"}.split.first.to_i
            counter = 1
            last_checkpoint_pos = 1
            while counter.to_i <= sizeOfLogfile.to_i
               currLine = %x{awk 'NR==#{counter}' "app/collabedit.log"}
               splits = currLine.split(@DELIMITER)

               if splits[1].tr("\n","") == "CHECKPOINT"
                  last_checkpoint_pos = counter
                  @lsn = splits[0].to_i
               end
               counter +=1
            end

            # perform recovery using logs
            files = {}
            last_checkpoint_pos += 1
            
            while last_checkpoint_pos.to_i <= sizeOfLogfile.to_i
               currLine = %x{awk 'NR==#{last_checkpoint_pos}' "app/collabedit.log"}
               splits = currLine.split(@DELIMITER)

               log_lsn  = splits[0]
               filename = splits[1]
               version  = splits[2]
               checksum = splits[3]
               author   = splits[4]
               node     = splits[5]
               offset   = splits[6]
               change   = splits[7]
      
               if files[filename] == nil
                  doc = Document.new(filename.to_s)
               else
                  doc = files[filename]
               end

               @lsn = log_lsn.to_i
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
                  files[filename] = doc
               end

               last_checkpoint_pos += 1
            end
            
            # write all these updated documents to disk
            files.each_pair do |k,v|
              checksum = Digest::MD5.hexdigest(v.rexml_doc.to_s)
              v.update_master(checksum, 0, @lsn.to_i)
            end
            
            @lsn += 1
            
            # delete the old log file
            File.delete(@logfilename)
         end 

         FileUtils.touch @logfilename
         @logfile = File.open(@logfilename, "a")
         log_to_file("CHECKPOINT")
    	end

      def debug(message)
        return unless @levels.include?('debug')
        log_to_stdout message, 'd'
      end

      def info(message)
        return unless @levels.include?('info')
        log_to_stdout message
      end

      def warning(message)
        return unless @levels.include?('warning')
        log_to_stdout message, 'w'
      end

      def recovery(message)
        log_to_file message 
        return unless @levels.include?('recovery')
        log_to_stdout message, 'r'
      end

      private
        def log_to_stdout(message, level = 'i')
          colors = { i: BLUE, d: BROWN, r: MAGENTA, w: RED }
          color  = @levels.include?('color') ? colors[level.to_sym] : RESET_COLORS
          puts color + "(" + level + ") " + Time.now.to_s + " " + message.to_s + RESET_COLORS
        end

        def log_to_file(message)
          @file_mutex.synchronize do
            # removed timestamp as it makes the log look creepy plus its 
            # not being used for recovery. LSN is used for that.
            #message = Time.now.to_s + @DELIMITER + message
            @lsn += 1
            @logfile.puts(@lsn.to_s + @DELIMITER + message)
            @logfile.flush
          end
        end
    end
end
