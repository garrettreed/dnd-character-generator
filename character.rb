#!/usr/bin/env ruby

require_relative "resource_pool.rb"


module DND
  class Character


    # Returns an array of characters.
    def self.crew( n = 1 )
      set, pool = [ ], DND::ResourcePool.new
      n.times { set.push DND::Character.new(pool) }
      return set
    end



    def self.select( n = self.def_quant )
      pool = DND::ResourcePool.new
      set = [ ]

      while set.length < n do
        char = DND::Character.new(pool, true)
        set.push(char) if char.want_to_keep?
      end

      return set
    end



    def self.to_file( chars )
      filename = "characters-#{chars.length}-#{Time.now.to_i}.txt"

      handle = File.new(filename, 'w')
      chars.each do |char|
        handle.puts(char.lines.join("\n"), "\n")
      end
      handle.close

      return filename
    end



    # Pass this an array of key-value pairs
    # and get a fully-formed Character in return.
    def self.from_lines( charr = [ ] )
      # puts "Generating character from: #{charr.to_s}"
      char = DND::Character.new(nil, nil)
      char.read_arr(charr)
      return char
    end



    def self.single_trait( act, n )
      set, refs, pool = [ ], DND::Character.acts_and_actions, DND::ResourcePool.new

      refs.each do |key,acts|
        if (key == act) or (act.include? key)
          n.times do
            char = DND::Character.new(pool, nil)
            char.send(acts[:pick])
            set.push(char.send(acts[:attr]))
          end
        end
      end

      return set
    end



    def self.acts_and_actions
      {
        'names' => { :pick => :pick_name, :attr => :name },
        'races' => { :pick => :pick_race, :attr => :race },
        'classes' => { :pick => :pick_class, :attr => :class },
        'aligns' => { :pick => :pick_alignment, :attr => :alignment },
        'items' => { :pick => :pick_item, :attr => :item },
        'traits' => { :pick => :pick_trait, :attr => :trait },
        'weapons' => { :pick => :pick_weapon, :attr => :weapon },
        'armors' => { :pick => :pick_armor, :attr => :armor },
        'profs' => { :pick => :pick_proficiencies, :attr => :profs },
        'spells' => { :pick => :pick_spells, :attr => :spells },
      }
    end


    def self.def_quant;  1 end
    def self.quant_spells; 2 end
    def self.quant_profs; 3 end




    def initialize( pool = nil, autogen = true )
      @name = ''
      @alignment = ''
      @race = ''
      @type = ''
      @trait = ''
      @weapon = ''
      @armor = ''
      @item = ''

      @profs = [ ]
      @spells = [ ]

      @hp = 0
      @gp = 0

      @pool = (pool.is_a? DND::ResourcePool) ? pool : DND::ResourcePool.new

      @type_key = ''

      self.gen if autogen
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
      # self.pool.load_names if (self.pool.names.nil? or self.pool.names.empty?)
      # self.name = self.pool.names.sample
      # self.pool.names.delete self.name

      # To enable random selection of first and last names,
      # uncomment the lines below and comment out the lines above.
      # Unique names are added to the pool's names array and, to
      # prevent duplicates in the crew, that array will be scanned
      # for the generated name before it's assigned.

      self.pool.load_names if (self.pool.names_f.nil? or self.pool.names_l.nil? or self.pool.names.nil?)
      nom_f = self.pool.names_f.sample
      nom_l = self.pool.names_l.sample
      self.name = "#{nom_f} #{nom_l}"
      self.pool.names_f.delete nom_f
      self.pool.names_l.delete nom_l

      # This is another method. It only checks for unique combinations, not repeated instances.
      # chk = self.pool.names_f.sample + ' ' + self.pool.names_l.sample
      # if self.pool.names.include? chk
      #   self.pick_name
      # else
      #   self.name = chk
      #   self.pool.names.push self.name
      # end
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
      res = DND::ResourcePool.weapons_files

      if res.is_a? String
        self.pool.load_weapons res

      else
        if self.is_class? 'fighter'
          if self.is_class? 'ranger'
            self.pool.load_weapons 'simple'
          else
            self.pool.load_weapons 'martial'
          end

        elsif self.is_class? 'rogue'
          self.pool.load_weapons 'exotic'

        else
          self.pool.load_weapons 'simple'
        end
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

      self.profs = profs.flatten.sample DND::Character.quant_profs
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

      self.spells = splls.flatten.sample(DND::Character.quant_spells)
    end



    #
    # And these ones are numbers of a collection of numbers.
    #

    def pick_stats
      stats = DND::Numbers.stats
      self.fill_stats stats
      self.adjust_stats
    end


    def fill_stats( arr = [ ] )
      self.stats = {
        'str' => arr[0],
        'con' => arr[1],
        'agi' => arr[2],
        'int' => arr[3],
        'wis' => arr[4],
        'cha' => arr[5]
      }
    end


    def adjust_stats( bonus = 6 )
      while !bonus.nil? and bonus > 0
        stat_key = self.stats.keys.sample
        stat_val = self.stats[stat_key]

        bonu = rand(1..bonus)
        if stat_val + bonu > 18
          x = 18 - stat_val
        else
          x = bonu
        end

        self.stats[stat_key] = stat_val + x
        bonus -= x
      end
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



    def want_to_keep?
      puts "\n"
      self.print
      $stdout.print "\nDo you want to keep this character? (y/N) "
      # $stdout.flush
      keep = $stdin.gets.chomp

      if keep == 'y'
        puts "Keeping."
        keep = true
      else
        puts "Skipping."
        keep = nil
      end

      return keep
    end



    def lines
      lines = [
        "Name: #{self.name}",
        "Race: #{self.race}",
        "Class: #{self.type}",
        "Alignment: #{self.alignment}",
        "Weapon: #{self.weapon_str}",
        "Armor: #{self.armor_str}"
      ]

      lines.push("Spells: #{self.spells_str}") if !self.spells.empty?

      lines.push(
        "Proficiencies: #{self.profs_str}",
        "Trait: #{self.trait}",
        "Item: #{self.item}",
        "Stats: #{self.stats.values.join(' ')}",
        "HP: #{self.hp}",
        "GP: #{self.gp}"
      )

      return lines
    end



    def print
      self.lines.each { |line| puts line }
    end


    def weapon_str
      "#{self.weapon['title']} #{self.weapon['damage_m']}"
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



    #
    # These methods are helpful for filling a character
    # from an array of strings. Each string in the array
    # should look like "key: val". This is useful for
    # generating a character from a file of data.
    #

    def read_arr( charr = [ ] )
      if charr.is_a?(Array)
        charr.each { |line| self.parse_line(line) }
      end
    end


    def parse_line( line )
      if m = line.match(/^([A-Za-z]+): (.*)$/)
        self.parse_attr(m[1].downcase, m[2])
      end
    end


    def parse_attr( title, value )
      if title == 'name'
        self.name = value
      elsif title == 'alignment'
        self.alignment = value
      elsif title == 'race'
        self.race = value
      elsif (title == 'class' or title == 'type')
        self.type = value
      elsif title == 'trait'
        self.trait = value
      elsif title == 'proficiencies'
        self.parse_profs_str(value)
      elsif title == 'spells'
        self.parse_spells_str(value)
      elsif title == 'weapon'
        self.parse_weapon_str(value)
      elsif title == 'armor'
        self.parse_armor_str(value)
      elsif title == 'item'
        self.item = value
      elsif title == 'stats'
        self.parse_stats_str(value)
      elsif title == 'hp'
        self.hp = value
      elsif title == 'gp'
        self.gp = value
      else
        raise Exception.new "WTF: '#{title}', '#{value}'"
      end
    end


    def parse_profs_str( str = '' )
      self.profs = [ ]
      profs = str.split(', ')
      profs.each do |prof|
        self.profs.push({ 'title' => prof.strip })
      end
    end


    def parse_spells_str( str = '' )
      self.spells = [ ]
      spells = str.split(', ')
      spells.each do |prof|
        self.spells.push({ 'title' => prof.strip })
      end
    end



    def parse_weapon_str( str = '' )
      if m = str.match(/\A(.*)([0-9]+d[0-9]+)\Z/)
        ret = {
          'title' => m[1].strip,
          'damage_m' => m[2]
        }
      else
        ret = {
          'title' => str,
          'damage_m' => '1d6',
        }
      end

      self.weapon = ret
    end


    def parse_armor_str( str = '' )
      self.armor = { }
      self.armor['title'] = str
    end


    def parse_stats_str( str = '' )
      self.fill_stats str.split(' ')
    end


  end
end
