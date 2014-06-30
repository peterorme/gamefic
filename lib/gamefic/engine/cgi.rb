require 'rubygems'
require 'json'

module Gamefic

  class Entity
    def key
      if @key == nil
        stack = Array.new
        stack.push name
        p = @parent
        while p != nil
          stack.push p.name
          p = p.parent
        end
        @key = stack.join("|")
      end
      @key
    end
  end

  module Cgi

    class Key
      def initialize(key_value)
        @value = key_value
      end
      def value
        @value
      end
    end

    class Engine < Gamefic::Engine
      attr_reader :user
      def initialize(plot, args = {})
        super(plot)
        @session_file = args[:session_file] || 'save.dat'
        @message_format = args[:message_format] || :html
        @response_format = args[:response_format] || :json
        @new_game = args[:new_game] || false
        @entity_keys = Hash.new
        @introducing = true
      end
      def post_initialize
        @user = Cgi::User.new @plot
      end
      def begin_session
        # Initialize keys for all entities
        @plot.entities.each { |e|
          @entity_keys[e.key] = e
        }
        if !@new_game and @session_file != nil
          if File.exist?(@session_file)
            load @session_file
            @introducing = false
          end
        end
      end
      def run
        if @introducing == true
          @plot.introduce @user.character
        else
          if @user.character.state.kind_of?(GameOverState) == false
            tick
          end
        end
        proc {
          $SAFE = Gamefic.safe_level
          response = Hash.new
          response[:output] = @user.stream.output
          response[:prompt] = @user.character.state.prompt
          response[:state] = @user.character.state.class.to_s.split('::').last
          puts JSON.generate(response)
        }.call
      end
      def end_session
        save @session_file
      end
      private
      def load(filename)
        x = File.open(filename, "r")
        ser = x.read
        x.close
        data = Marshal.restore(ser)
        data.each { |k, h|
          if k == 'yourself'
            entity = @entity_keys['yourself']
          else
            entity = @entity_keys[k]
          end
          h.each { |s, v|
            if s == :session
              entity.instance_variable_set(:@session, v)
            else
              writer = "#{s.to_s[1..-1]}="
              writer.untaint
              proc {
                $SAFE = Gamefic.safe_level
                if entity.respond_to?(writer)
                  if v.kind_of?(Key)
                    entity.send(writer, @entity_keys[v.value])
                  elsif v.kind_of?(CharacterState)
                    v.instance_variable_set(:@character, entity)
                    entity.instance_variable_set(s, v)
                  elsif v.kind_of?(Array)
                    entity.send(writer, decode_array(v))
                  else
                    entity.send(writer, v)
                  end
                end
              }.call
            end
          }
        }
        @restored = true
      end
      def save(filename)
        data = Hash.new
        @plot.entities.each { |e|
          data[e.key] = entity_hash(e)
        }
        f = File.new(filename, "w")
        f.write Marshal.dump data
        f.close
      end
      def entity_hash(e)
        hash = Hash.new
        e.instance_variables.each { |v|
          writer = "#{v.to_s[1..-1]}="
          if e.respond_to?(writer)
            value = e.instance_variable_get(v)
            if value.kind_of?(String) or value.kind_of?(Numeric) or value.kind_of?(TrueClass) or value.kind_of?(FalseClass) or value.kind_of?(Entity) or value.kind_of?(Character) or value.kind_of?(CharacterState) or value == nil or value.kind_of?(Array)
              if value.kind_of?(Entity)
                if value == @user.character
                  hash[v] = Key.new('yourself')
                else
                  hash[v] = Key.new(value.key)
                end
              elsif value.kind_of?(CharacterState)
                value.instance_variable_set(:@character, nil)
                hash[v] = value
              elsif value.kind_of?(Array)
                hash[v] = encode_array(value)
              else
                hash[v] = value
              end
            end
          end
        }
        hash[:session] = e.session
        hash
      end
      def encode_array(array)
        result = Array.new
        array.each { |item|
          if item.kind_of?(Entity)
            result.push Key.new(item.key)
          else
            result.push item
          end
        }
        result
      end
      def decode_array(array)
        result = Array.new
        array.each { |item|
          if item.kind_of?(Key)
            result.push @entity_keys[item.value]
          else
            result.push item
          end
        }
        result    
      end
    end
    
    class User < Gamefic::User
      def post_initialize
        @stream = Cgi::UserStream.new
        @state = UserState.new self
        #@character = @plot.make Character, :name => 'player'
      end
    end
    
    class UserStream < Gamefic::UserStream
      def output
        @output ||= Array.new
      end
      def send(data)
        output.push data.strip
      end
      def select(prompt)
        # TODO: non-blocking read
        line = STDIN.gets
        @queue.push line
      end
    end

  end

end
