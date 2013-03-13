module CollaborativeEditing
    class Document
        # This class represent the document
        # its purpose is to manage the content,
        # its changes and its history

        UPDATE_FREQUENCY = 5        
        attr_reader :name, :version, :rexml_doc
        
        def initialize(name)
            @name = name
            @version = 0     
            
            # server maintains all files under $COLLAB_EDITOR_HOME/data/
            # if file exists, then send its contents, else create a new file with default content
            if !File.file?("data/" + name) # + ".ver." + @version.to_s)
                # replicate the default file
                FileUtils.cp("app/default.file", "data/" + name) # + ".ver." + @version.to_s) 
            end
            @rexml_doc = REXML::Document.new(File.new("data/" + name)) # + ".ver." + @version.to_s))          
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
            # if current version number is a multiple of UPDATE_FREQUENCY, 
            # update the master file with the latest contents
            if @version % UPDATE_FREQUENCY == 0
                update_master checksum
            end
        end
        
        # Bring the base copy in sync with current version of the file
        def update_master(checksum)
            @rexml_doc[1][1].string = "version = " + @version.to_s
            @rexml_doc[1][3].string = "md5_checksum = " + checksum
            @rexml_doc[1][5].string = "lsn = " + (Application.logger.lsn.to_i + 1).to_s
            
            FileUtils.cp("data/" + name, "data/" + name + ".swp") 
            File.open("data/" + name, 'w') {|f| f.write(@rexml_doc) }
            log_checkpoint(checksum, "base")
            
            FileUtils.cp("data/" + name, "data/" + name + ".swp")
            log_checkpoint(checksum, "swp")
        end
        
        def secure_change_in_logs(checksum, change)
            Application.logger.recovery @name.to_s + Application.logger.DELIMITER \
                + @version.to_s             + Application.logger.DELIMITER \
                + checksum                  + Application.logger.DELIMITER \
                + "change_file"             + Application.logger.DELIMITER \
                + change.username.to_s      + Application.logger.DELIMITER \
                + change.position.node.to_s + Application.logger.DELIMITER \
                + change.position.y.to_s
                #+ " !$! " + msg[:changes]
        end
                
        def log_checkpoint(checksum, type)
            Application.logger.recovery name + Application.logger.DELIMITER \
                             + @version.to_s + Application.logger.DELIMITER \
                             + checksum      + Application.logger.DELIMITER \
                             + "check_point" + Application.logger.DELIMITER \
                             + type
        end
    end
end
