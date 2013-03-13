module CollaborativeEditing
    class Logger
    
    	def initialize(logfile_name, levels)
    	   @logfilename = logfile_name
         @level       = levels
    		
    	     # TODO: before doing anything, apply recovery from the existing log file
           # delete an existing log file from older revision
           if File.file?(@logfilename)
             File.delete(@logfilename)
           end
      
           # open the log file in append mode
           @logfile = File.open(@logfilename, "a")      
    	end

      def debug(message)
        return unless @level.include?('debug')
        log_to_stdout message, 'd'
      end

      def info(message)
        return unless @level.include?('info')
        log_to_stdout message
      end

      def recovery(message)
        log_to_file message 
        return unless @level.include?('recovery')
        log_to_stdout message, 'r'
      end

      private

        def log_to_stdout(message, level = 'i')
          puts "[logger] (" + level + ") " + Time.now.to_s + " " + message.to_s
        end

        def log_to_file(message)
          message = Time.now.to_s + " !$! " + message
          @logfile.puts(message)
          @logfile.flush
        end
    end
end
