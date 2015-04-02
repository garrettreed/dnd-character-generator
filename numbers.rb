#!/usr/bin/env ruby


module DND
  class Numbers


    def self.bound_high; 18 end
    def self.bound_low;   6 end
    def self.def_quant;   6 end
    def self.def_sets;    1 end

    def self.def_lims
      {
        :sets => DND::Numbers.def_sets,
        :quant => DND::Numbers.def_quant,
        :high => DND::Numbers.bound_high,
        :low => DND::Numbers.bound_low
      }
    end


    #
    # A few convenience methods for stats, hit points, and gold.
    #

    def self.stats( n = 1 )
      return DND::Numbers.new({
                                :sets => n,
                                :quant => 6,
                                :high => 18,
                                :low => 6
                              }).set
    end

    def self.hp(n = 1 )
      return DND::Numbers.new({
                                :sets => n,
                                :quant => 1,
                                :high => 20,
                                :low => 10
                              }).set
    end

    def self.gp( n = 1 )
      return DND::Numbers.new({
                                :sets => n,
                                :quant => 1,
                                :high => 500,
                                :low => 1
                              }).set
    end




    def initialize( u_lim = { } )
      defs = DND::Numbers.def_lims
      i_lim = (u_lim.is_a? Hash) ? defs.merge(u_lim) : defs

      @sets = (i_lim[:sets].nil?) ? 0 : i_lim[:sets].to_i
      @quantity = (i_lim[:quant].nil?) ? 0 : i_lim[:quant].to_i
      @lim_high = (i_lim[:high].nil?) ? 0 : i_lim[:high].to_i
      @lim_low = (i_lim[:low].nil?) ? 0 : i_lim[:low].to_i

      if @lim_high < @lim_low
        @lim_high, @lim_low = @lim_low, @lim_high
      end

      # puts "quant: #{@quantity}, low: #{@lim_low}, high: #{@lim_high}"

      self.gen
    end

    attr_reader :quantity, :lim_high, :lim_low, :sets
    attr_accessor :set



    def gen
      self.set = [ ]

      self.sets.times do
        s = [ ]
        self.quantity.times { s.push rand(self.lim_low..self.lim_high) }
        self.set.push s
      end

      self.set = self.set.first if self.sets < 2
    end

  end
end
