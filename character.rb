#!/usr/bin/env ruby

require_relative "resource_pool.rb"


module DND
  class Character


    def self.def_quant;  1 end



    # Returns an array of characters.
    def self.crew( n = 1 )
      set, pool = [ ], DND::ResourcePool.new
      n.times { set.push DND::Character.new(pool) }
      return set
    end




    def initialize( pool = nil )
      @pool = (pool.is_a? DND::ResourcePool) ? pool : DND::ResourcePool.new

      @name, @alignment, @race, @type, @trait, @profs, @spells, @weapon, @armor, @item, @stats, @hp, @gp = '', '', '', '', '', [ ], [ ], '', '', '', { }, 0, 0

      @type_key = ''

      self.gen
    end

    attr_reader :pool
    attr_accessor :name, :alignment, :race, :type_key, :type, :trait, :profs, :spells, :weapon, :armor, :item, :stats, :hp, :gp



    def gen
      self.pick_name
      self.pick_race
      self.pick_class
      self.pick_alignment
      self.pick_item
      self.pick_trait
      self.pick_armor
      self.pick_weapon
      self.pick_proficiencies
      self.pick_spells if self.gets_spells?
      self.pick_stats
      self.pick_hp
      self.pick_gp
    end



    #
    # These characteristics don't depend on others.
    #

    def pick_name
      self.pool.load_names if (self.pool.names.nil? or self.pool.names.empty?)
      self.name = self.pool.names.sample
      self.pool.names.delete self.name
    end

    def pick_race
      self.pool.load_races if self.pool.races.nil?
      self.race = self.pool.races.sample
    end

    def pick_class
      self.pool.load_classes if self.pool.classes.nil?
      self.type_key = self.pool.classes.keys.sample
      self.type = self.pool.classes[self.type_key].sample
    end

    def pick_alignment
      self.pool.load_alignments if self.pool.alignments.nil?
      self.alignment = self.pool.alignments.sample
    end

    def pick_item
      self.pool.load_items if (self.pool.items.nil? or self.pool.items.empty?)
      self.item = self.pool.items.sample
      self.pool.items.delete self.item
    end

    def pick_trait
      self.pool.load_traits if (self.pool.traits.nil? or self.pool.traits.empty?)
      self.trait = self.pool.traits.sample
      self.pool.traits.delete self.trait
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


    def pick_weapon
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

      wkey = self.pool.weapons.keys.sample
      self.weapon = self.pool.weapons[wkey].sample
    end



    def pick_proficiencies
      profs = [ ]

      # The general proficiencies.
      self.pool.load_proficiencies
      profs.push self.pool.proficiencies

      # The race-based proficiencies.
      races = %w{ dwarf elf gnome halfling }
      races.each do |race|
        if self.is_race? race
          self.pool.load_proficiencies race
          profs.push self.pool.proficiencies
        end
      end

      # The class-based proficiencies.
      classes = %w{ fighter mage monk rogue }
      classes.each do |closs|
        if self.is_class? closs
          self.pool.load_proficiencies closs
          profs.push self.pool.proficiencies
        end
      end

      self.profs = profs.flatten.sample 3
    end



    def pick_spells
      splls = [ ]

      # This could be expanded but it will work for entry-level characters.
      levels = %w{ level0 level1 level2 }
      # The class-based spells.
      classes = %w{ bard cleric druid paladin ranger }
      classes.each do |closs|
        if self.is_class? closs
          self.pool.load_spells closs
          levels.each do |level|
            if self.pool.spells.has_key? level
              splls.push self.pool.spells[level]
            end
          end
        end
      end

      # The general spells.
      self.pool.load_spells
      levels.each do |level|
        if self.pool.spells.has_key? level
          # Necromancer spells are special.
          if !self.is_class? 'necro'
            self.pool.spells[level].delete 'necro'
          end

          self.pool.spells[level].each do |key,arr|
            splls.push arr
          end
        end
      end

      self.spells = splls.flatten.sample 3
    end



    #
    # And these ones are numbers of a collection of numbers.
    #

    def pick_stats
      stats = DND::Numbers.stats
      self.stats = {
        'str' => stats[0],
        'con' => stats[1],
        'agi' => stats[2],
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

    def gets_spells?
      chks, ret = %w{ mage monk Bard }, nil
      chks.each { |chk| ret = true if self.is_class?(chk) }
      return ret
    end


    def is_race?( chk = '' )
      if self.race.downcase.include?(chk) then true else nil end
    end

    def is_class?( chk = '' )
      if ((self.type.downcase.include?(chk)) or (self.type_key == chk)) then true else nil end
    end

    def is_alignment?( chk = '' )
      if (self.alignment.downcase.include?(chk)) then true else nil end
    end




    def print
      puts "Name: #{self.name}"
      puts "Race: #{self.race}"
      puts "Class: #{self.type}"
      puts "Alignment: #{self.alignment}"
      puts "Weapon: #{self.weapon_str}"
      puts "Armor: #{self.armor_str}"
      puts "Spells: #{self.spells_str}"
      puts "Proficiencies: #{self.profs_str}"
      puts "Trait: #{self.trait}"
      puts "Item: #{self.item}"
      puts "Stats: #{self.stats.values.join ' '}"
      puts "HP: #{self.hp}"
      puts "GP: #{self.gp}"
    end


    def weapon_str
      "#{self.weapon['title'] + ' ' + self.weapon['damage_m']}"
    end

    def armor_str
      self.armor['title']
    end


    def spells_str
      uses = ""
      if !self.spells.empty?
        self.spells.each { |s| uses << "#{s['title']}; " }
        uses = uses.chomp "; "
      end
      return uses
    end


    def profs_str
      uses = ""
      if !self.profs.empty?
        self.profs.each { |s| uses << "#{s['title']}; " }
        uses = uses.chomp "; "
      end
      return uses
    end


  end
end
