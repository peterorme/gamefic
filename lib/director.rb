module Gamefic

	class Director
		def self.dispatch(actor, command)
			command.strip!
			statements = actor.story.instructions.parse(command)
			options = Array.new
			statements.each { |statement|
				actions = actor.story.commands[statement.command]
				if actions != nil
					actions.each { |action|
						orders = bind_contexts_in_result(actor, statement, action)
						orders.each { |order|
							args = Array.new
							args.push actor
							order.arguments.each { |a|
								if a.length > 1
									longnames = Array.new
									a.each { |b|
										longnames.push b.longname
									}
									actor.tell "I don't know which you mean: #{longnames.join(', ')}"
									return
								end
								args.push a[0]
							}
							options.push [order.action.proc, args, order.action.specificity]
						}
					}
				end
			}
			options.sort! { |a,b|
				b[2] <=> a[2]
			}
			options.push([
				Proc.new { |actor|
					actor.tell "I don't know what you mean by '#{command}.'"
				}, [actor], -1
			])
			del = Delegate.new(options)
			del.execute
		end
		private
		def self.bind_contexts_in_result(actor, statement, action)
			objects = Array.new
			valid = true
			prepared = Array.new
			arguments = statement.arguments.clone
			action.contexts.each { |context|
				arg = arguments.shift
				if arg == nil or arg == ''
					valid = false
					next
				end
				if context == String
					prepared.push [arg]
				#elsif context == :parent
				#	result = Query.match(arg, [actor.parent])
				#elsif context == :self
				#	result = Query.match(arg, [actor])
				elsif context.kind_of?(Query)
					if context.kind_of?(Subquery)
						last = prepared[prepared.length - 1]
						if last == nil or last.length > 1
							valid = false
							next
						end
						result = context.execute(last[0], arg)
					else
						result = context.execute(actor, arg)
					end
					if result.objects.length == 0
						valid = false
						next
					else
						prepared.push result.objects
						if result.remainder
							arguments.push result.remainder
						end
					end
				else
					# TODO: Better message
					raise "Invalid object"
				end
				#bind = context.match(actor, arg)
				#if bind.objects.length == 0
				#	valid = false
				#	next
				#end
				#if arguments.length == 0
				#	arguments.push bind.remainder
				#end
				#prepared.push bind.objects
			}
			if valid == true
				objects.push Order.new(action, prepared)
			end
			return objects
		end
	end
	
	class Director
		class Delegate
			@@delegation_stack = Array.new
			def initialize(options)
				@options = options
			end
			def execute
				@@delegation_stack.push @options
				if @options.length > 0
					opt = @options.shift
					if opt[1].length == 1
						opt[0].call(opt[1][0])
					else
						opt[0].call(opt[1])
					end
				end
				@@delegation_stack.pop
			end
			def self.passthru
				if @@delegation_stack.last != nil
					if @@delegation_stack.last.length > 0
						opt = @@delegation_stack.last.shift
						if opt[1].length == 1
							opt[0].call(opt[1][0])
						else
							opt[0].call(opt[1])
						end
					end
				end
			end
		end
		class Order
			attr_reader :action, :arguments
			def initialize(action, arguments)
				@action = action
				@arguments = arguments
			end
		end
	end

end
