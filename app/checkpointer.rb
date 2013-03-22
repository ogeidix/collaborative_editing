require "thread"

module CollaborativeEditing
    class Checkpointer

    	def initialize()
    		@scheduled = false
    		@mutex     = Mutex.new
			@resource  = ConditionVariable.new
			Application.logger.debug "[checkpointer] init"
			run()
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
				Application.logger.recovery "CHECKPOINT"
	   		end
    end
end