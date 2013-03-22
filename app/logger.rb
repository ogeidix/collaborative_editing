module CollaborativeEditing
    class Logger

      #foreground color
      BLACK   = "\033[30m"
      RED     = "\033[31m"
      GREEN   = "\033[32m"
      BROWN   = "\033[33m"
      BLUE    = "\033[34m"
      MAGENTA = "\033[35m"
      CYAN    = "\033[36m"
      GRAY    = "\033[37m"

      #ANSI control chars
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

           if File.file?(@logfilename)
              @lsn = %x{wc -l < "#{@logfilename}"}.to_i
           else 
              @lsn = 0
           end

         @logfile = File.open(@logfilename, "a")      
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
            #message = Time.now.to_s + @DELIMITER + message
            @lsn += 1
            @logfile.puts(message)
            @logfile.flush
          end
        end
    end
end
