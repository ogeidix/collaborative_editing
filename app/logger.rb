module CollaborativeEditing
    class Logger

    	def initialize(logfile_name)
    		@logfile_name = logfile_name
    		puts "[logger #{@logfile_name}] init logger"
    	end

    	def log(message)
			puts "[logger #{@logfile_name}] " + message.to_s
    	end
    end
end