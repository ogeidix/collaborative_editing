###############################################################################
## Document
###############################################################################
## this class represent the Document (the file content)
## it is able to execute the changes, write log files and, update master copy
##

module CollaborativeEditing
    class Document

        # This class represent the document its purpose is 
        # to manage the content, its changes and its history

        # this is a global counter for changes that are in memory
        @@operations_since_checkpoint = 0
        
        # After indicates the frequency after which we write
        # the in-memory copy of files to disk
        CHECKPOINT_FREQUENCY = 5     

        attr_reader :filename, :version, :rexml_doc, :history
        
        def self.reset_operations_since_checkpoint   
          @@operations_since_checkpoint = 0   # reset
        end
        
        def initialize(filename)
            @filename = filename
            @version = 0
            @history = {}
            
            # server maintains all files under $COLLAB_EDITOR_HOME/data/
            # if file does not exists, create a new file with default content
            if !File.file?("data/" + filename)
                # replicate the default file
                FileUtils.cp("app/default.file", "data/" + filename)
                @rexml_doc = REXML::Document.new(File.new("data/" + filename))
            else 
                # if the file already exists, then use it
                @rexml_doc = REXML::Document.new(File.open("data/" + filename))
            end
        end
    
        def execute_change(this_change, toLog)
            this_change.perform_change(self)
            
            # add this change to the history of the file
            @history[@version] = this_change
            
            # increment the version
            @version += 1
            
            if toLog == true
                checksum = Digest::MD5.hexdigest(@rexml_doc.to_s)
                secure_change_in_logs(checksum, this_change)
                @@operations_since_checkpoint += 1

                if @@operations_since_checkpoint >= CHECKPOINT_FREQUENCY
                  Application.checkpointer.schedule!
                end
            end
        end
        
        # Bring the on-disk copy in sync with in-memory version of the file
        def update_master(checksum, lsn_increment = 1, lsn = -1)
        
            # update the meta-information in the file
            @rexml_doc[1][1].string = "version = " + @version.to_s
            @rexml_doc[1][3].string = "md5_checksum = " + checksum
            if lsn == -1
              @rexml_doc[1][5].string = "lsn = " + (Application.logger.lsn.to_i + lsn_increment).to_s
            else
              @rexml_doc[1][5].string = "lsn = " + (lsn.to_i + lsn_increment).to_s
            end
            
            # write the in-memory version of the file to the disk
            File.open("data/" + filename, 'w') {|f| f.write(@rexml_doc) }
        end
        
        # Create the log message for the operation performed and pass this 
        # to the logger code which will write it to the log file
        # Log structure is:
        # <lsn> <filename> <version> <checksum> <username> <node> <offset> <change type> <change meta>
        #
        # The <change meta> for insertion is just the data inserted.
        # For deletion, we need to store the direction and length of chars deleted.
        #
        # NOTE: Currently we are not using checksum for any logic. It
        #       could be used for checking consistency of disk copy.
        def secure_change_in_logs(checksum, this_change)            
            log  = @filename.to_s                   + Logger::DELIMITER
            log += @version.to_s                    + Logger::DELIMITER
            log += checksum                         + Logger::DELIMITER
            log += this_change.username.to_s        + Logger::DELIMITER
            log += this_change.position.node.to_s   + Logger::DELIMITER 
            log += this_change.position.offset.to_s + Logger::DELIMITER

            if this_change.is_a? Insertion
                log += "insertion"             + Logger::DELIMITER
                log += this_change.content     + Logger::DELIMITER
            elsif this_change.is_a? Deletion
                log += "deletion"              + Logger::DELIMITER
                log += this_change.direction   + Logger::DELIMITER
                log += this_change.length.to_s + Logger::DELIMITER
            end

            # invoke the logger function to log this to the log file
            # it will add the lsn automatically
            Application.logger.recovery log
        end
    end
end
