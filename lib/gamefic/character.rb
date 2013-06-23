module Gamefic

	class Character < Entity
		attr_reader :state, :queue, :user
		def post_initialize
			self.state = CharacterState
			@queue = Array.new
		end
		def connect(user)
			@user = user
		end
		def disconnect
			# TODO: We might need some cleanup here. Like, move the character out of the game, or set a timeout to allow dropped users to reconnect... figure it out.
			@user = nil
		end
		def perform(command)
			#if command != nil
			#	@queue.push command
			#end
			if state.busy? == false
				Director.dispatch(self, command)
			else
				@queue.push command
			end
		end
		#def inject(command)
		#	Director.dispatch(self, command)
		#end
		def tell(message, refresh = false)
			if user != nil and message.to_s != ''
				user.stream.send "#{message}\n"
				if (refresh == true)
					user.refresh
				end
			end
		end
		def state=(state_class)
			@state = state_class.new(self)
		end
	end
	class CharacterState
		def initialize(user)
			@user = user
			post_initialize
		end
		def post_initialize
			# TODO: Required by subclasses?
		end
		def busy?
			false
		end
		def update
			# TODO: Since this is an idle state, commands should have already gotten performed. What else needs to be done here?
			while (line = @user.queue.shift)
				@user.perform line
				if @user.state != self
					break
				end
			end
		end
	end

end