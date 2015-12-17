#!/usr/bin/env ruby


module DND
  class Hub


    def self.require_files
      DND::Hub.required_files.each do |req|
        req = "#{__dir__}/#{req}"
        if File.exists?(req)
          require_relative(req)
        else
          raise Exception.new("Critical hit! DND is missing required file '#{req}'.")
        end
      end
    end


    def self.required_files
      %w{ utils.rb numbers.rb character.rb charsheet.rb }
    end



    def self.with_args( args = [ ] )
      DND::Hub.require_files
      dnd = DND::Hub.new(args)
      dnd.main
    end



    def initialize( args = [ ] )
      @args = (args.is_a?(Array)) ? args : nil
      @err = nil
    end

    attr_reader :args
    attr_accessor :err



    # The idea is that #parse_args will assign a proc or an array of
    # procs to the instance's @act, which will be called here. If an
    # action is not specified, then an error message will be printed.
    def main
      actions = parse_instructions(self.parse_args(self.args))

      if actions.is_a?(Proc) || actions.is_a?(Array)
        return act_on_procs(actions)
      else
        print_error
        return nil
      end
    end





    protected



    # Arguments take the form {action} {flag} {number}, where
    # {action} is the command, like `char` or `stats`,
    # {flag} is optional and depends on the action, and
    # {number} is the quantity of {action}s to generate.
    # Examples: `chars 12`, `sheets -c 40`, `names 20`
    # The {action} is required. The {flag} is not. If the {number}
    # is absent, then a sensible default will be used. The `:var`
    # can be useful for things like a file name.
    def parse_args( arr = [ ] )
      ret = {
        :act => nil,    # The main action.
        :flag => nil,   # Action modifier.
        :quant => nil,  # The quantity.
        :var => nil     # Variable. E.g., a filename.
      }

      arr.each do |arg|
        if m = arg.match(/^[0-9]+$/)
          ret[:quant] = m[0].to_i

        elsif m = arg.match(/^-+([A-Za-z])$/)
          ret[:flag] = m[1].downcase

        elsif m = arg.match(/^[A-Za-z]+$/)
          if ret[:act].nil?
            ret[:act] = m[0].downcase
          else
            ret[:var] = m[0].downcase
          end

        else
          ret[:var] = arg
        end
      end

      return ret
    end



    def parse_instructions( inx = { } )
      ret = nil

      if inx.is_a?(Hash)
        if inx[:act].nil? || inx[:act] == 'help' ||
           inx[:flag] == 'help' || inx[:flag] == 'h'
          self.err = File.read('help-message.md')

        else
          # For character sheets.
          if inx[:act].include?('sheet')
            ret = parse_sheets_instructions(inx)

          # For characters. Below `sheet` in case of 'charsheet'.
          elsif inx[:act].include?('char')
            ret = parse_character_instructions(inx)

          # For character sheets from a file.
          elsif inx[:act].include?('file')
            ret = parse_file_instructions(inx)

          # For stats.
          elsif inx[:act].include?('stat')
            ret = parse_stats_instructions(inx)

          # For single selections from a character. The commands are
          # the keys of Character::acts_and_actions.
          elsif DND::Character.acts_and_actions.keys.include?(inx[:act])
            ret = parse_singles_instructions(inx)

          else
            self.err = "Quitting: #{inx[:act]} is not a valid command."
          end
        end

      else
        self.err = "Quitting: no arguments."
      end

      return ret
    end



    def parse_sheets_instructions( inx )
      ret = nil

      n = (inx[:quant].nil?) ? DND::CharSheet.def_quant : inx[:quant]

      if inx[:flag].nil?
        ret = lambda { DND::CharSheet.new(n) }

      # c is for cherrypick.
      elsif inx[:flag] == 'c'
        ret = [
          lambda { DND::Character.select(n * DND::CharSheet.chars_per_sheet) },
          lambda { |chars| DND::Character.to_file(chars) },
          lambda { |file| DND::CharSheet.from_file(file) }
        ]

      else
        self.err = "Quitting: '#{inx[:flag]}' is not a valid flag for character sheets."
      end

      return ret
    end



    def parse_character_instructions( inx )
      ret = nil

      n = (inx[:quant].nil?) ? DND::Character.def_quant : inx[:quant]

      if inx[:flag].nil?
        ret = lambda do
          DND::Character.crew(n).each do |char|
            char.print
            puts "\n"
          end
        end

      # c is for cherrypick.
      elsif inx[:flag] == 'c'
        ret = [
          lambda { DND::Character.select(n) },
          lambda { |chars| DND::Character.to_file(chars) }
        ]

      else
        self.err = "Quitting: '#{inx[:flag]}' not a valid flag for characters."
      end

      return ret
    end



    def parse_file_instructions( inx )
      ret = nil

      if inx[:var].is_a?(String)
        ret = lambda { DND::CharSheet.from_file(inx[:var]) }
      else
        self.err = "Quitting: given file command but no file name."
      end

      return ret
    end



    def parse_stats_instructions( inx )
      n = (inx[:quant].nil?) ? DND::Numbers.def_sets : inx[:quant]

      ret = lambda do
        nums = DND::Numbers.stats(n)

        if n > 1
          nums.each { |n| puts n.to_s }
        else
          puts nums.to_s
        end
      end

      return ret
    end



    def parse_singles_instructions( inx )
      n = (inx[:quant].nil?) ? DND::Character.def_quant : inx[:quant]

      ret = lambda do
        selects = DND::Character.single_trait(inx[:act], n)
        selects.each { |nom| puts nom }
      end

      return ret
    end



    # If given an array of procs, then each proc after the first
    # will be passed the return of the preceding proc. The first
    # proc should use the command line arguments. And the return
    # will be what is returned from the last proc called.
    def act_on_procs( procs )
      ret = nil

      if procs.is_a?(Proc)
        ret = procs.call

      elsif procs.is_a?(Array)
        procs.each do |proc|
          if proc.is_a?(Proc)
            ret = (ret.nil?) ? proc.call : proc.call(ret)
          end
        end

      else
        print_error
      end

      return ret
    end



    def print_error( msg = self.err )
      if msg.is_a?(String)
        puts msg
      else
        puts "Something unknown is doing something we don't know what. That is what our knowledge amounts to."
      end
    end

  end
end




# Run it.
DND::Hub.with_args(ARGV)
