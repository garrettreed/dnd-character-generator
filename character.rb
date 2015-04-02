#!/usr/bin/env ruby

require_relative "resource_pool.rb"


module DND
  class Character



    def self.crew( n = 1 )
      n.times { DND::Character.new.print }
    end




    def initialize( pool = nil )
      @pool = (pool.is_a? DND::ResourcePool) ? pool : DND::ResourcePool.new

      @name, @alignment, @race, @type, @trait, @profs, @spells, @weapon, @armor, @item, @stats, @hp, @gp = '', '', '', '', '', [ ], [ ], '', '', '', { }, 0, 0

      @type_key = ''
    end

    attr_reader :pool
    attr_accessor :name, :alignment, :race, :type_key, :type, :trait, :profs, :spells, :weapon, :armor, :item, :stats, :hp, :gp



    #
    # These characteristics don't depend on others.
    #

    def pick_name
      self.pool.load_names if self.pool.names.nil?
      self.name = self.pool.names.sample
    end

    def pick_race
      self.pool.load_races if self.pool.races.nil?
      self.race = self.pool.races.sample
    end

    def pick_class
      self.pool.load_classes if self.pool.classes.nil?
      cls = self.pool.classes.sample
      self.type_key = cls.key
      self.type = cls.sample
    end

    def pick_alignment
      self.pool.load_alignments if self.pool.alignments.nil?
      self.alignment = self.pool.alignments.sample
    end

    def pick_item
      self.pool.load_items if self.pool.items.nil?
      self.item = self.pool.items.sample
    end

    def pick_trait
      self.pool.load_traits if self.pool.traits.nil?
      self.trait = self.pool.traits.sample
    end



    #
    # These ones do.
    #

    def pick_armor
      self.pool.load_armors if self.pool.armors.nil?
      armors = self.pool.armors

      if self.is_class? 'fighter'
        key = 'heavy'
      elsif self.is_class? 'rogue'
        key = 'medium'
      else
        key = 'light'
      end

      self.armor = armors[key].sample
    end


    def pick_weapons
      if self.is_class? 'fighter'
        if self.is_class? 'ranger'
          self.pool.load_weapons "simple"
        else
          self.pool.load_weapons "martial"
        end

      elsif self.is_class? 'rogue'
        self.pool.load_weapons 'exotic'

      else
        self.pool.load_weapons "simple"
      end

      self.weapon = self.pool.weapons.sample.sample
    end



    #HERE
    def pick_proficiencies
      self.pool.load_names if self.pool.names.nil?
      self.name = self.pool.names.sample
    end

    def pick_spells
      self.pool.load_names if self.pool.names.nil?
      self.name = self.pool.names.sample
    end



    #
    # And these ones are numbers of a collection of numbers.
    #

    def pick_stats
      stats = DND::Numbers.stats
      self.stats = {
        'str' => stats[0],
        'con' => stats[1],
        'dex' => stats[2],
        'int' => stats[3],
        'wis' => stats[4],
        'cha' => stats[5]
      }
    end


    def pick_hp
      self.hp = DND::Numbers.hp
    end

    def pick_gp
      self.gp = DND::Numbers.gp
    end



    #
    # These are helpers.
    #

    def is_race?( chk = '' )
      if self.race.downcase.include?(chk) then true else nil end
    end

    def is_class?( chk = '' )
      if ((self.type.downcase.include?(chk)) or (self.type_key == chk)) then true else nil end
    end

    def is_alignment?( chk = '' )
      if (self.alignment.downcase.include?(chk)) then true else nil end
    end


  end
end


# char = DND::Character.new.pick_name
