#!/usr/bin/env ruby

require_relative "lib/utils.rb"

module DND
  class Campaign

    #
    # Call this to start the procedure.
    #

    def self.run( args = [ ] )
      args = (args.is_a?(Array)) ? args : [ ]
      Campaign.new(args)
    end


    def self.acts_and_actions
      {
        'names' => { :pick => :pick_name, :attr => :name },
        'races' => { :pick => :pick_race, :attr => :race },
        'classes' => { :pick => :pick_type, :attr => :type },
        'aligns' => { :pick => :pick_alignment, :attr => :alignment },
        'items' => { :pick => :pick_item, :attr => :item },
        'traits' => { :pick => :pick_trait, :attr => :trait },
        'weapons' => { :pick => :pick_weapon, :attr => :weapon },
        'armors' => { :pick => :pick_armor, :attr => :armor },
        'profs' => { :pick => :pick_proficiencies, :attr => :profs },
        'spells' => { :pick => :pick_spells, :attr => :spells },
      }
    end



    #
    # Instance methods.
    #

    def initialize( args = [ ] )
      act = get_action(self.get_instruction(args))

      if ((act.is_a?(Proc)) || (act.is_a?(Array)))
        return run_action(act)
      else
        print_error("Something unknown is doing something we don't know what. That is what our knowledge amounts to.")
        return nil
      end
    end


    protected

    # Arguments take the form {action} {flag} {number}, where
    # {action} is the command, like `char` or `stats`,
    # {flag} is optional and depends on the action, and
    # {number} is the quantity of {action}s to generate.
    # Examples: `chars 12`, `sheets -c 5`, `names 20`
    # The {action} is required. The {flag} is not. If the {number}
    # is absent, then a sensible default will be used. The `:var`
    # can be useful for things like a file name.
    def get_instruction( args = [ ] )
      inx = {
        :act => nil,    # The main action.
        :flag => nil,   # Action modifier.
        :quant => nil,  # The quantity.
        :var => nil     # Variable. E.g., a filename.
      }

      args.each do |arg|
        if (arg.numeric?)
          inx[:quant] = arg.to_i
        elsif (m = arg.match(/^-+([A-Za-z])$/))
          inx[:flag] = m[1].downcase
        elsif (m = arg.match(/^[A-Za-z]+$/))
          if inx[:act].nil?
            inx[:act] = m[0].downcase
          else
            inx[:var] = m[0].downcase
          end
        else
          inx[:var] = arg
        end
      end

      return inx
    end


    def get_action( inx )
      # For the main help message.
      if ((inx[:act].nil?) || (inx[:act] == 'help') ||
          (inx[:flag] == 'help') || (inx[:flag] == 'h'))
        return make_error_action(File.read('help-message.md'))

      # For character sheets.
      elsif (inx[:act].include?('sheet'))
        return make_sheet_action(inx)

      # For characters. Below `sheet` in case of 'charsheet'.
      elsif (inx[:act].include?('char'))
        return make_character_action(inx)

      # For character sheets from a file.
      elsif (inx[:act].include?('file'))
        return make_file_action(inx)

      # For stats.
      elsif (inx[:act].include?('stat'))
        return make_stats_action(inx)

      # For single selections from a character. The commands are
      # the keys of Campaign::acts_and_actions.
      elsif (Campaign.acts_and_actions.keys.include?(inx[:act]))
        return make_singles_action(inx)

      else
        return make_error_action("Quitting: #{inx[:act]} is not a valid command.")
      end
    end



    #
    # Make Action methods.
    #
    # These all receive an instruction hash and return either a
    # lambda or an array of lambdas. If an array, each one will
    # receive the return of the one run before it.
    #

    def make_sheet_action( inx )
      require_relative "lib/charsheet.rb"

      n = (inx[:quant].is_a?(Integer)) ? inx[:quant] : CharSheet.def_quant

      if (inx[:flag].nil?)
        return [
          lambda { Character.crew(n * CharSheet.chars_per_sheet) },
          lambda { |chars| Character.to_file(chars) },
          lambda { |file| CharSheet.from_file(file) }
        ]

      # c is for cherrypick.
      elsif (inx[:flag] == 'c')
        return [
          lambda { Character.select(n * CharSheet.chars_per_sheet) },
          lambda { |chars| Character.to_file(chars) },
          lambda { |file| CharSheet.from_file(file) }
        ]

      else
        return make_error_action("Quitting: '#{inx[:flag]}' is not a valid flag for character sheets.")
      end
    end


    def make_character_action( inx )
      require_relative "lib/character.rb"

      n = (inx[:quant].is_a?(Integer)) ? inx[:quant] : Character.def_quant

      if (inx[:flag].nil?)
        ret = lambda do
          Character.crew(n).each do |char|
            char.print
            puts "\n"
          end
        end
        return ret

      # c is for cherrypick.
      elsif (inx[:flag] == 'c')
        return [
          lambda { Character.select(n) },
          lambda { |chars| Character.to_file(chars) }
        ]

      else
        return make_error_action("Quitting: '#{inx[:flag]}' not a valid flag for characters.")
      end
    end


    def make_file_action( inx )
      require_relative "lib/charsheet.rb"

      if (inx[:var].is_a?(String))
        return lambda { CharSheet.from_file(inx[:var]) }
      else
        return make_error_action("Quitting: given file command but no file name.")
      end
    end


    def make_stats_action( inx )
      require_relative "lib/numbers.rb"

      n = (inx[:quant].is_a?(Integer)) ? inx[:quant] : Numbers.def_sets

      ret = lambda do
        nums = Numbers.stats(n)
        if (n > 1)
          nums.each { |n| puts n.to_s }
        else
          puts nums.to_s
        end
      end

      return ret
    end


    def make_singles_action( inx )
      require_relative "lib/character.rb"

      n = (inx[:quant].is_a?(Integer)) ? inx[:quant] : Character.def_quant

      ret = lambda do
        selects = Character.single_trait(inx[:act], n)
        selects.each { |nom| puts nom }
      end

      return ret
    end


    def make_error_action( msg )
      return lambda { puts msg }
    end



    # If given an array of procs, then each proc after the first
    # will be passed the return of the preceding proc. The first
    # proc should use the command line arguments. And the return
    # will be what is returned from the last proc called.
    def run_action( act )
      if (act.is_a?(Proc))
        return act.call

      elsif act.is_a?(Array)
        ret = nil
        act.each do |proc|
          ret = (ret.nil?) ? proc.call : proc.call(ret)
        end
        return ret

      else
        raise "Can't run action: need a Proc or a Array of Procs."
      end
    end


    def print_error( msg, exc = nil )
      if (exc.nil?)
        puts msg
      else
        raise msg
      end
    end

  end
end


# Run it.
DND::Campaign.run(ARGV)
