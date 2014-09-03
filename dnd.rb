#!/usr/bin/ruby




class DND

  def initialize( args = [ ] )
  end

  attr_reader :args
  attr_accessor :numbers



  def numbers( n = 6, lim = 18 )
    ret = [ ]
    n.times { ret.push rand(6..lim) }
    return ret
  end


end


x = DND.new.numbers(6)
puts x.join(' ')
