module DND
  class Numbers


    # This is the number of sets of numbers.
    # If the class is initialized with a :sets => 1, then
    # it will return an array. Else, an array of arrays.
    def self.def_sets; 1 end

    # This is the number of numbers.
    def self.def_quant; 6 end

    # This is the upper limit of the randomness.
    def self.bound_high; 18 end

    # This is the lower limit of the randomness.
    def self.bound_low; 6 end


    def self.def_lims
      {
        :sets => Numbers.def_sets,
        :quant => Numbers.def_quant,
        :high => Numbers.bound_high,
        :low => Numbers.bound_low
      }
    end


    #
    # A few convenience methods for stats, hit points, and gold.
    #

    def self.stats( n = 1 )
      return Numbers.new({
                                :sets => n,
                                :quant => 6,
                                :high => 18,
                                :low => 6
                              }).set
    end

    def self.hp(n = 1 )
      return Numbers.new({
                                :sets => n,
                                :quant => 1,
                                :high => 20,
                                :low => 10
                              }).set[0]
    end

    def self.gp( n = 1 )
      return Numbers.new({
                                :sets => n,
                                :quant => 1,
                                :high => 500,
                                :low => 1
                              }).set[0]
    end




    attr_accessor :set

    protected


    def initialize( u_lims = { } )
      defs = Numbers.def_lims
      lims = (u_lims.is_a?(Hash)) ? defs.merge(u_lims) : defs

      sets = (lims[:sets].nil?) ? 0 : lims[:sets].to_i
      quant = (lims[:quant].nil?) ? 0 : lims[:quant].to_i
      high = (lims[:high].nil?) ? 0 : lims[:high].to_i
      low = (lims[:low].nil?) ? 0 : lims[:low].to_i

      if high < low
        high, low = low, high
      end

      # puts "quant: #{@quantity}, low: #{@lim_low}, high: #{@lim_high}"

      @set = self.gen(sets, quant, low, high)
    end



    def gen( sets, quant, low, high )
      ret = [ ]

      sets.times do
        s = [ ]
        quant.times { s.push(rand(low..high)) }
        ret.push(s)
      end

      if sets == 1
        return ret[0]
      else
        return ret
      end
    end

  end
end
