module CollaborativeEditing
    class Logger
    
    	def initialize(logfile_name)
    	   @logfilename = logfile_name
    		
    	     # TODO: before doing anything, apply recovery from the existing log file
           # delete an existing log file from older revision
           if File.file?(@logfilename)
             File.delete(@logfilename)
           end
      
           # open the log file in append mode
           @logfile = File.open(@logfilename, "a")      
    	end

    	def log(message)
    	   @logfile.puts(message)
         @logfile.flush
    	end
    end
end
