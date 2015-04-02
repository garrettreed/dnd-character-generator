#!/usr/bin/env ruby


module DND
  class Hub


    def self.with( args = [ ] )
      DND::Hub.require_files
      dnd = DND::Hub.new args
    end


    def self.require_files
      DND::Hub.required_files.each do |req|
        req = "#{__dir__}/#{req}"
        if File.exists? req
          require_relative req
        else
          raise Exception.new("Critical hit! DND is missing required file '#{req}'.")
        end
      end
    end


    def self.required_files
      # charsheet.rb
      %w{ utils.rb numbers.rb character.rb }
    end




    def initialize( args = [ ] )
      @args, @act, @err_msg = args, nil, nil
      self.main
    end

    attr_reader :args
    attr_accessor :act, :err_msg



    # The idea is that #parse_args will assign a proc
    # to the instance's action, which will be called here.
    # If an action is not specified, then an error message
    # will be printed.
    def main
      self.parse_args
      if self.act.is_a? Proc
        self.act.call
      else
        self.print_error
      end
    end



    # Arguments to take the form {string} {number}, where
    # {string} is the command and
    # {number} is the quantity of {strings} to generate.
    # Examples: sheets 40, chars 12, stats 1
    # The {string} is required. If the {number} is absent,
    # then a sensible default will be used.
    def parse_args
      if (self.args.is_a? Array) and (self.args.length > 0)

        act = (self.args[0].is_a? String) ? self.args[0].downcase : ''
        if self.args.length == 2
          num = (self.args[1].numeric?) ? self.args[1].to_i : 1
        else
          num = nil
        end

        # For character sheets.
        if act.include? 'sheet'
          howmany = (num.nil?) ? DND::Charsheets.def_quant : num
          self.act = Proc.new { DND::CharSheet.new(howmany) }

        # For characters.
        elsif act.include? 'char'
          howmany = (num.nil?) ? DND::Charsheets.def_quant : num
          self.act = Proc.new { DND::Character.new(howmany) }

        # For stats.
        elsif act.include? 'stat'
          howmany = (num.nil?) ? DND::Numbers.def_sets : num
          self.act = Proc.new do
            nums = DND::Numbers.stats(howmany)
            if howmany > 1
              nums.each { |n| puts n.to_s }
            else
              puts nums.to_s
            end
          end

        else
          self.err_msg = "Invalid action: #{act}."
        end

      else
        self.err_msg = "No arguments. Aborting."
      end
    end



    def print_error
      if self.err_msg.is_a? String
        puts self.err_msg
      else
        puts "Something unknown is doing something we don't know what. That is what our knowledge amounts to."
      end
    end

  end
end


# n = Numbers.new
# puts n.numbers(6, 18, 6).join(' ')
# puts n.numbers(1, 20, 10).join(' ')
# puts n.numbers(1, 300, 0).join(' ')

DND::Hub.with ARGV
