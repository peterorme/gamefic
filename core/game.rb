require "core/grammar.rb"
require "core/keywords.rb"
require "core/entity.rb"
#require "core/context.rb"
require "core/action.rb"
require "core/parser.rb"
require "core/director.rb"
require "core/story.rb"

Dir["core/features/*.rb"].each { |file|
	require file
}
Dir["core/entities/*.rb"].each { |file|
	require file
}

class Array
	def that_are(cls)
		delete_if { |i| i.kind_of?(cls) == false }
	end
end

module Gamefic

	class Game
		def initialize
			@player = nil
			@start = nil
		end
		def turn(input)
			action = @player.perform(input)
		end
		def run(player)
			@player = player
			@running = true
			while @running == true
				print "\n[#{player.parent.name.cap_first}]> "
				turn(STDIN.gets)
			end	
		end
	end

end
