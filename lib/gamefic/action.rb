module Gamefic

	class Action
		attr_reader :command, :order_key
		@@defaults = Array.new
    @@order_key_seed = 0
		def initialize(story, command, *queries, &proc)
      @plot = story
      @order_key = @@order_key_seed
      @@order_key_seed += 1
			if (command.kind_of?(Symbol) == false and !command.nil?)
				raise "Action commands must be symbols"
			end
			if (queries.length + 1 != proc.arity) and (queries.length == 0 and proc.arity != -1)
				raise "Number of contexts is not compatible with proc arguments"
			end
			@command = command
			@queries = queries
			@proc = proc
			if story == nil
				@@defaults.push self
			else
				story.send :add_action, self
			end
		end
		def self.defaults
			@@defaults.clone
		end
		def specificity
			spec = 0
			magnitude = 1
			@queries.each { |q|
				if q.kind_of?(Query::Base)
					spec += (q.specificity * magnitude)
				else
					spec += magnitude
				end
				#magnitude = magnitude * 10
			}
			return spec
		end
		def key
			@key
		end
		def queries
			@queries
		end
    def execute *args
      @proc.call *args
    end
		private
			def self.explode(entity)
				arr = Array.new
				arr.push entity
				cls = entity.class
				while cls != Object
					arr.push cls
					cls = cls.superclass
				end
				arr.push String
				arr.push nil
			end
	end

end
