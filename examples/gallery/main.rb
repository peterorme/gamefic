#
# This is an evolving gallery of things you can do in gamefic.
#
# This already includes some things that may be pretty hard to do in 
# other systems: 
# - getting the system clock
# - creating objects on the fly
# - unit testing a story
# 
# One non-standard thing we do here is at the bottom of the file, where
# there's a "test me" command. This uses code in the import/script.rb 
# file. 

import 'standard'

import 'script' # this is for the "test me" command 

# This is just a room.
# Since we place the player here in the introduction, we need
# to have it come before the introduction.

lobby = make Room, 
	:name => 'lobby', 
	:description => "The lobby is rather empty, void of people (well, except you) and any sort of intrinsic artistic value."

# Here's a clock that shows your own time. You can take it.

clock = make Thing,
	:name => 'clock', 
	:parent => lobby

# note that we're not changing the description as such, but overriding the look
# The Query::Family works whether or not you are carrying the clock
respond :look, Query::Family.new(clock) do |actor, item|
  actor.tell "A very basic wall clock. The time is " + Time.now().strftime("%H:%M") + "."
end

# This is the first thing that happens in the game.

introduction do |player|
  player.parent = lobby
  player.perform "look"
end

# Just another room. 

storage = make Room, 
	:name => 'storage', 
	:description => "The storage room is long and narrow, a bit smelly, and littered with some stuff that looks like an infinite number of pebbles."

# OK, let's connect the two rooms 
lobby.connect storage, "west"


# This is rather silly. But there's apparently an infinite number of pebbles on the 
# floor. 
# (Peter Orme adds: I'm not sure whether you're supposed to do this...)
pebbles = make Thing, 
	:name => "lot of pebbles",
	:parent => storage

respond :take, Query::Family.new(pebbles) do |actor, item|
	make Thing, :name => "pebble", :parent => actor
	actor.tell "You pick up a pebble."
end


# This is a test script, using the Script module in import/script.rb
# You could use this just to make walkthroughs (like Inform7's "test" command)
# but it also lets you write a very basic kind of unit tests. 
#
# For the basic scripted actions, just use scripted.instruction "command", and 
# it will be just like the player typed that command. 
# 
# You can also use this syntax: scripted.assertTrue proc {...} "Failure message"
# 
# The code inside the proc (the curly brackets) should evaluate to true. 
# It can just be a comparison, or whatever code you can think of that evaluates to
# true. (Remember - in Ruby, most things are true!)
#
# While playing the game, you can trugger the test with the command "test me".
# 
respond :test, Query::Text.new() do |actor, string|
	
	# Set up the "scripted actor"
	scripted = Script::Scripted.new actor

	scripted.assertTrue proc { true }, "Returning true should be ok."
	
	# A proc that does not return true counts as a failed test:
    scripted.assertTrue proc {false}, "deliberately returning false to provoke failure"

	scripted.assertTrue proc {
		actor.parent == lobby
	}, "The player should begin in the lobby."

	scripted.instruction "examine clock"
	
	scripted.instruction "take it"
	
	# look at this: we can just change the game world without having the player perform commands. 
	scripted.tell "(teleporting to the storage)"
	actor.parent = storage

	# note the difference between scripted.instruction and actor.perform - if you 
	# do actor.perform, the actual command is never printed.
	actor.perform "look"

	scripted.assertTrue proc {
		actor.parent == storage
	}, "The player should have been teleported to the storage area."

	scripted.assertTrue proc { clock.parent == actor }, "The player should have the clock."

	scripted.report
end

