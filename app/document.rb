module CollaborativeEditing
    class Document

        # This class represent the document its purpose is 
        # to manage the content, its changes and its history

        # this is a global counter for changes that are in memory
        @@operations_since_checkpoint = 0
        
        # After indicates the frequency after which we write
        # the in-memory copy of files to disk
        @@UPDATE_FREQUENCY = 5     

        attr_reader :filename, :version, :rexml_doc, :history
        
        def operations_since_checkpoint  
          @@operations_since_checkpoint  # getter
        end

        def reset_operations_since_checkpoint   
          @@operations_since_checkpoint = 0   # reset
        end

        def UPDATE_FREQUENCY
          @@UPDATE_FREQUENCY    # getter
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
                # if the file already exists, then
                # return it
                                # perform recovery using logs before returning the file to the user
                @rexml_doc = REXML::Document.new(File.new("data/" + filename))
                dirty = false
                @version = @rexml_doc[0][1].string.split[2].to_i
                checksum = @rexml_doc[0][3].string
                lastLSN = @rexml_doc[0][5].string.split[2].to_i
                sizeOfLogfile = %x{wc -l "app/collabedit.log"}.split.first.to_i

                # read the log file from this LSN and apply all the changes 
                # logged for this file.
                counter = lastLSN.to_i

                while counter.to_i <= sizeOfLogfile.to_i
                   currLine = %x{awk 'NR==#{counter}' "app/collabedit.log"}
                   splits = currLine.split(Application.logger.DELIMITER)
                   
                   if splits[0] == filename   # if the log corresponds to the same file
                      position      = Position.new(splits[5], splits[6].to_i , splits[1].to_i)
                      change_done = splits[7].tr("\n","")
                      logged_change = Change.new(splits[4], position, change_done)
                      execute_change(logged_change, false)
                      puts(currLine)
                      dirty = true
                   end
                   counter +=1
                end
                
                # write back this document to disk so that we need not perform
                # the recovery again
                if dirty == true
                    checksum = Digest::MD5.hexdigest(@rexml_doc.to_s)
                    update_master(checksum, 0)
                end

            end
        end
    
        def execute_change(this_change, toLog)
            parent_node = REXML::XPath.first @rexml_doc, this_change.position.parent_node
            i = 0
            n = 0
            c = this_change.position.child_number.to_i
            while (i < c) do
                i +=1 if(parent_node.children[n].class == REXML::Text)
                n += 1
            end

            current_node = parent_node.children[n-1]            
            prefix = current_node.value[0, this_change.position.offset]
            suffix = current_node.value[this_change.position.offset, current_node.value.length]
            interim = ""
            
            if this_change.is_a? Deletion
                this_length = this_change.length
                if this_change.direction.eql?('left')
                    prefix  = current_node.value[0, this_change.position.offset - this_length]
                else 
                    suffix = current_node.value[this_change.position.offset + this_length, current_node.value.length]
                end
            elsif this_change.is_a? Insertion
                interim = this_change.content.to_s 
            end
            current_node.value = prefix + interim + suffix
            
            # add this change to the history of the file
            @history[@version] = this_change
            
            # increment the version
            @version += 1
            
            if toLog == true
                checksum = Digest::MD5.hexdigest(@rexml_doc.to_s)
                secure_change_in_logs(checksum, this_change)
                @@operations_since_checkpoint += 1
            end
        end
        
        # Bring the on-disk copy in sync with in-memory version of the file
        def update_master(checksum, lsn_increment = 1)
        
            # update the meta-information in the file
            @rexml_doc[1][1].string = "version = " + @version.to_s
            @rexml_doc[1][3].string = "md5_checksum = " + checksum
            @rexml_doc[1][5].string = "lsn = " + (Application.logger.lsn.to_i + lsn_increment).to_s
            
            # write the in-memory version of the file to the disk
            File.open("data/" + filename, 'w') {|f| f.write(@rexml_doc) }
        end
        
        # Create the log message for the operation performed and pass this 
        # to the logger code which will write it to the log file
        # Log structure is:
        # <filename> <version> <checksum> <username> <node> <offset> <change type> <change meta>
        #
        # The <change meta> for insertion is just the data inserted.
        # For deletion, we need to store the direction and length of chars deleted.
        #
        # NOTE: Currently we are not using checksum for any logic that
        #       could be possibly used for checking consistency of disk
        def secure_change_in_logs(checksum, this_change)            
            log  = @filename.to_s                   + Application.logger.DELIMITER
            log += @version.to_s                    + Application.logger.DELIMITER
            log += checksum                         + Application.logger.DELIMITER
            log += this_change.username.to_s        + Application.logger.DELIMITER
            log += this_change.position.node.to_s   + Application.logger.DELIMITER 
            log += this_change.position.offset.to_s + Application.logger.DELIMITER

            if this_change.is_a? Insertion
                log += "insertion"             + Application.logger.DELIMITER
                log += this_change.content     + Application.logger.DELIMITER
            elsif this_change.is_a? Deletion
                log += "deletion"              + Application.logger.DELIMITER
                log += this_change.direction   + Application.logger.DELIMITER
                log += this_change.length.to_s + Application.logger.DELIMITER
            end

            # invoke the logger function to log this to the log file
            Application.logger.recovery log
        end
    end
end
