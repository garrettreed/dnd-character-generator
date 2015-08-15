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
      %w{ utils.rb numbers.rb character.rb charsheet.rb }
    end




    def initialize( args = [ ] )
      @args = args
      @act = nil
      @err_msg = nil

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

      if self.act.is_a?(Proc)
        self.act.call
      elsif self.act.is_a?(Array)
        self.act.each { |x| x.call if x.is_a?(Proc) }
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
      if self.args.is_a?(Array) && (self.args.length > 0)

        act = (self.args[0].is_a?(String)) ? self.args[0].downcase : ''
        switch = nil

        if self.args.length == 3
          if self.args[1].numeric? && self.args[2].is_a?(String)
            num = self.args[1].to_1
            switch = self.args[2]
          elsif self.args[2].numeric? && self.args[1].is_a?(String)
            num = self.args[2].to_i
            switch = self.args[1]
          else
            self.err_msg = "Ignoring invalid arguments: #{self.args.to_s}."
          end
        elsif self.args.length == 2
          num = (self.args[1].numeric?) ? self.args[1].to_i : 1
        else
          num = nil
        end


        # For character sheets.
        if act.include?('sheet')
          howmany = (num.nil?) ? DND::CharSheet.def_quant : num
          if switch == '-c'
            self.act = lambda { DND::CharSheet.from_file(DND::Character.to_file(DND::Character.select(howmany))) }
          else
            self.act = lambda { DND::CharSheet.new(howmany) }
          end


        # For character sheets from a file.
        elsif act.include?('file')
          self.act = lambda { DND::CharSheet.from_file(args[1]) }


        # For characters.
        elsif act.include?('char')
          howmany = (num.nil?) ? DND::Character.def_quant : num
          self.act = lambda do
            chars = DND::Character.crew(howmany)
            chars.each do |char|
              char.print
              puts "\n"
            end
          end


        # For stats.
        elsif act.include?('stat')
          howmany = (num.nil?) ? DND::Numbers.def_sets : num
          self.act = lambda do
            nums = DND::Numbers.stats(howmany)
            if howmany > 1
              nums.each { |n| puts n.to_s }
            else
              puts nums.to_s
            end
          end


        # For single selections from a character.
        # The list of commands is the array of keys in DND::Character.acts_and_actions
        elsif DND::Character.acts_and_actions.keys.include?(act)
          howmany = (num.nil?) ? DND::Character.def_quant : num
          self.act = lambda do
            selects = DND::Character.single_trait(act, howmany)
            selects.each { |nom| puts nom }
          end


        else
          self.err_msg = "Invalid action: #{act}."
        end

      else
        self.err_msg = "No arguments. Aborting."
      end
    end



    def print_error
      if self.err_msg.is_a?(String)
        puts self.err_msg
      else
        puts "Something unknown is doing something we don't know what. That is what our knowledge amounts to."
      end
    end

  end
end




# Run it.
DND::Hub.with(ARGV)
