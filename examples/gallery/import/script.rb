# This is a module for "Scripting" things in the game, for taking over an actor. 
# This can be used for "in-game testing"

module Script

	class Scripted
	
		 def initialize(actor)
			@actor = actor
			@ok=0
			@fail=0
		end 

		attr_reader :actor, :ok, :fail

		# Have the player attempt a command. This is like if the player
		# typed in the command.
		def instruction (command)
			@actor.tell @actor.state.prompt + command
			@actor.perform command
		end

		# Just tell the player something
		# param  message  A string that gets displayed to the player.
		def tell (message)
			actor.tell message
		end

		# Very basic unit testing-style assertion.
		# param  check    a proc that should return true
		# param  message  a message that gets printed if the proc is not true
		def assertTrue (check, message)

			test = check.call
			unless test==true
				@actor.tell "FAIL: " + message
				@fail = @fail + 1
			else 
				@ok = @ok + 1
			end
		end

		# prints out a summary of the test results
		def report
			puts "Tests: #{@ok} ok, #{@fail} failures."
			if (@fail > 0)
				puts "*** THERE WERE FAILURES *** "
			else 
				puts "*** ALL TESTS PASSED ***"
			end
		end
	end
end
