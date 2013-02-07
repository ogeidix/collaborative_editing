module CollaborativeEditing
	class Room
		@@rooms = {}

		def self.for(document)
			@@rooms[document] ||= Room.new(document)
		end

		def initialize(document)
			@document  = Document.new(document)
			@listeners = []
		end

		def publish(channel, message)
			@listeners.each { |l| l.call(channel, message) }
		end

		def subscribe(&block)
			@listeners << block
		end

	end
end