module CollaborativeEditing
    class Document

        # This class represent the document
        # its purpose is to manage the content,
        # its changes and its history

        @@operations_since_checkpoint = 0
        @@UPDATE_FREQUENCY = 5        

        attr_reader :filename, :version, :rexml_doc
        
        def operations_since_checkpoint
          @@operations_since_checkpoint
        end

        def reset_operations_since_checkpoint
          @@operations_since_checkpoint = 0
        end

        def UPDATE_FREQUENCY
          @@UPDATE_FREQUENCY
        end
        
        def initialize(filename)
            @filename = filename
            @version = 0
            
            # server maintains all files under $COLLAB_EDITOR_HOME/data/
            # if file does not exists, create a new file with default content
            if !File.file?("data/" + filename)
                # replicate the default file
                FileUtils.cp("app/default.file", "data/" + filename)
                @rexml_doc = REXML::Document.new(File.new("data/" + filename))
            else 
                # if the file already exists, then
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
                      execute_change(logged_change)
                      puts(currLine)
                      dirty = true
                   end
                   counter +=1
                end
                
                # write back this document to disk so that we need not perform
                # the recovery again
                if dirty == true
                    checksum = Digest::MD5.hexdigest(@rexml_doc.to_s)
                    update_master(checksum)
                end
            end
        end
    
        def execute_change(this_change)
#            puts "Parent: #{this_change.position.parent_node} - Child Num. #{this_change.position.child_number}"
            parent_node = REXML::XPath.first @rexml_doc, this_change.position.parent_node
            i = 0
            n = 0
            c = this_change.position.child_number.to_i
            while (i < c) do
                i +=1 if(parent_node.children[n].class == REXML::Text)
                n += 1
            end
            
            current_node = parent_node.children[n-1]
            if  this_change.change[0].ord == 8
                this_length = this_change.change.length
                prefix  = current_node.value[0, this_change.position.y - this_length]
                interim = ""
            else
                prefix  = current_node.value[0, this_change.position.y] 
                interim = this_change.change.to_s 
            end

            suffix = current_node.value[this_change.position.y, current_node.value.length]
            current_node.value = prefix + interim + suffix
            # puts "Changed node : " + current_node.value
            
            @version += 1
            checksum = Digest::MD5.hexdigest(@rexml_doc.to_s)
            secure_change_in_logs(checksum, this_change)
            @@operations_since_checkpoint += 1
        end
        
        # Bring the base copy in sync with current version of the file
        def update_master(checksum)
            @rexml_doc[1][1].string = "version = " + @version.to_s
            @rexml_doc[1][3].string = "md5_checksum = " + checksum
            @rexml_doc[1][5].string = "lsn = " + (Application.logger.lsn.to_i + 1).to_s
            
            FileUtils.cp("data/" + filename, "data/" + filename + ".swp") 
            File.open("data/" + filename, 'w') {|f| f.write(@rexml_doc) }
#            log_checkpoint(checksum, "base")
            
            FileUtils.cp("data/" + filename, "data/" + filename + ".swp")
#            log_checkpoint(checksum, "swp")
        end
        
        def secure_change_in_logs(checksum, this_change)
            Application.logger.recovery @filename.to_s + Application.logger.DELIMITER \
                + @version.to_s                  + Application.logger.DELIMITER \
                + checksum                       + Application.logger.DELIMITER \
                + "change_file"                  + Application.logger.DELIMITER \
                + this_change.username.to_s      + Application.logger.DELIMITER \
                + this_change.position.node.to_s + Application.logger.DELIMITER \
                + this_change.position.y.to_s    + Application.logger.DELIMITER \
                + this_change.change
        end

        def log_checkpoint(checksum, type)
            Application.logger.recovery filename + Application.logger.DELIMITER \
                             + @version.to_s + Application.logger.DELIMITER \
                             + checksum      + Application.logger.DELIMITER \
                             + "check_point" + Application.logger.DELIMITER \
                             + type
        end
    end
end
