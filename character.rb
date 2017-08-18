#!/usr/bin/env ruby

require_relative "resource_pool.rb"


module DND
  class Character


    # Returns an array of characters.
    def self.crew( n = self.def_quant )
      set = [ ]
      pool = DND::ResourcePool.new
      n.times { set.push(DND::Character.new(pool)) }

      return set
    end



    # Returns the same as ::crew but prints the character and
    # prompts to keep or skip it before adding it to the crew.
    def self.select( n = self.def_quant )
      pool = DND::ResourcePool.new
      set = [ ]

      while set.length < n do
        char = DND::Character.new(pool, true)

        if char.want_to_keep?([set.length, n])
          set.push(char)
          pool.remove_unique_attrs(char)
        end
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



    def self.from_file( filename )
      f = File.open(filename)
      chars = [ ]
      lines = [ ]
      working = nil

      f.each do |line|
        line = line.chomp

        if line.empty?
          chk = self.from_lines(lines)
          chars.push(chk) if chk.is_a?(DND::Character)
          working = nil
          lines = [ ]

        else
          working = true
          lines.push(line)
        end
      end

      if working
        chk = self.from_lines(lines)
        chars.push(chk) if chk.is_a?(DND::Character)
      end

      return chars
    end



    # Pass this an array of key-value pairs and get a fully-formed
    # Character in return.
    def self.from_lines( charr = [ ] )
      char = DND::Character.new(nil, nil)
      char.read_arr(charr)
      return char
    end



    def self.single_trait( act, n )
      refs = DND::Character.acts_and_actions
      pool = DND::ResourcePool.new
      set = [ ]

      refs.each do |key,acts|
        if (key == act) or (act.include? key)
          n.times do
            char = DND::Character.new(pool, nil)
            set.push(char.send(acts[:pick], char.pool))
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
      @alignment = ''
      @armor = ''
      @item = ''
      @name = ''
      @race = ''
      @trait = ''
      @type = ''
      @type_key = ''
      @weapon = ''

      @profs = [ ]
      @spells = [ ]

      @gp = 0
      @hp = 0

      @pool = (pool.is_a?(DND::ResourcePool)) ? pool : DND::ResourcePool.new

      self.gen(@pool) if autogen
    end


    attr_reader :pool
    attr_accessor :alignment, :armor, :gp, :hp, :item, :name, :profs, :race, :spells, :stats, :trait, :type, :type_key, :weapon



    def gen( pool )
      # These are the simplest.
      self.alignment = self.pick_alignment(pool)
      self.item = self.pick_item(pool)
      self.name = self.pick_name(pool)
      self.race = self.pick_race(pool)
      self.trait = self.pick_trait(pool)

      # This returns a hash.
      cls = self.pick_class(pool)
      self.type = cls[:class]
      self.type_key = cls[:key]

      self.armor = self.pick_armor(pool)
      self.weapon = self.pick_weapon(pool)
      self.profs = self.pick_proficiencies(pool)
      self.spells = self.pick_spells(pool) if self.gets_spells?

      # These generate numbers.
      self.stats = self.pick_stats
      self.hp = self.pick_hp
      self.gp = self.pick_gp
    end




    #
    # These characteristics don't depend on others.
    #

    def pick_name( pool )
      pool.init_names if (pool.names_f.nil? || pool.names_l.nil? || pool.names.nil?)

      chk = pool.names_f.sample + ' ' + pool.names_l.sample

      if pool.names.include?(chk)
        chk = self.pick_name(pool)
      else
        pool.names.push(chk)
      end

      return chk
    end



    def pick_race( pool )
      pool.init_races if pool.races.nil?
      return pool.races.sample
    end



    def pick_class( pool )
      pool.init_classes if pool.classes.nil?
      key = pool.classes.keys.sample
      nom = pool.classes[key].sample
      return { :key => key, :class => nom }
    end



    def pick_alignment( pool )
      pool.init_alignments if pool.alignments.nil?
      return pool.alignments.sample
    end



    def pick_item( pool )
      pool.init_items if (pool.items.nil? or pool.items.empty?)
      return pool.items.sample
    end



    def pick_trait( pool )
      pool.init_traits if (pool.traits.nil? or pool.traits.empty?)
      return pool.traits.sample
    end




    #
    # These ones do.
    #

    # `pool.armors` must be a hash or an array.
    def pick_armor( pool )
      pool.init_armors if pool.armors.nil?

      if (pool.armors.is_a?(Hash))
        if self.is_class?('fighter')
          key = 'heavy'
        elsif self.is_class?('rogue')
          key = 'medium'
        else
          key = 'light'
        end

        if (pool.armors.has_key?(key))
          return pool.armors[key].sample
        else
          return pool.armors[pool.armors.keys.sample].sample
        end

      else
        return pool.armors.sample
      end
    end



    def pick_weapon( pool )
      res = DND::ResourcePool.weapons_files

      if res.is_a?(String)
        pool.init_weapons(res) if (pool.weapons.nil? or pool.weapons.empty?)

      else
        if self.is_class?('fighter')
          if self.is_class?('ranger')
            pool.init_weapons('simple')
          else
            pool.init_weapons('martial')
          end

        elsif self.is_class?('rogue')
          pool.init_weapons('exotic')

        else
          pool.init_weapons('simple')
        end
      end

      return pool.weapons[pool.weapons.keys.sample].sample
    end



    def pick_proficiencies( pool, quant = DND::Character.quant_profs )
      pool.init_proficiencies if pool.proficiencies.nil?

      profs = [ ]
      profs.push(pool.proficiencies)

      %w{ dwarf elf gnome halfling }.each do |race|
        profs.push(pool.load_proficiencies(race)) if self.is_race?(race)
      end

      %w{ fighter mage monk rogue }.each do |closs|
        profs.push(pool.load_proficiencies(closs)) if self.is_class?(closs)
      end

      return profs.flatten.sample(quant)
    end



    def pick_spells( pool, quant = DND::Character.quant_spells )
      pool.init_spells if pool.spells.nil?

      spells = [ ]

      # This could be expanded but it will work for entry-level characters.
      levels = %w{ level0 level1 level2 }

      # The general spells.
      levels.each do |level|
        if pool.spells.has_key?(level)
          chk_sp = pool.spells[level].clone

          # Necromancer spells are special.
          chk_sp.delete('necro') if !self.is_class?('necro')
          chk_sp.each { |key,arr| spells.push(arr) }
        end
      end

      # The class-based spells.
      %w{ bard cleric druid paladin ranger }.each do |closs|
        if self.is_class?(closs)
          chk_sp = pool.load_spells(closs)

          levels.each do |level|
            spells.push(chk_sp[level]) if chk_sp.has_key?(level)
          end
        end
      end

      return spells.flatten.sample(quant)
    end




    #
    # And these ones are numbers or a collection of numbers.
    #


    def pick_stats
      return self.adjust_stats(self.fill_stats(DND::Numbers.stats))
    end



    def fill_stats( arr = [ ] )
      return {
        'str' => arr[0],
        'con' => arr[1],
        'agi' => arr[2],
        'int' => arr[3],
        'wis' => arr[4],
        'cha' => arr[5]
      }
    end



    def adjust_stats( stats, bonus = 6 )
      ret = stats

      while !bonus.nil? and bonus > 0
        stat_key = ret.keys.sample
        stat_val = ret[stat_key]

        bonu = rand(1..bonus)
        if stat_val + bonu > 18
          x = 18 - stat_val
        else
          x = bonu
        end

        ret[stat_key] = stat_val + x
        bonus -= x
      end

      return ret
    end



    def pick_hp
      return DND::Numbers.hp
    end


    def pick_gp
      return DND::Numbers.gp
    end




    #
    # These check against the instance's values.
    #

    def gets_spells?
      ret = nil
      %w{ mage monk Bard }.each { |chk| ret = true if self.is_class?(chk) }
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




    #
    # These are not related to character-building but to retaining,
    # printing, reading, etc.
    #


    def want_to_keep?( nums = [ ] )
      puts "\n"
      self.print

      $stdout.print "\nDo you want to keep this character? "
      if (nums.length == 2)
        $stdout.print "It would be \##{nums[0] + 1} of #{nums[1]}. "
      end
      $stdout.print "(y/N): "

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

      lines.push("Spells: #{self.str_from_list(self.spells)}") if !self.spells.empty?

      lines.push(
        "Proficiencies: #{self.str_from_list(self.profs)}",
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



    def str_from_list( list, key = 'title' )
      uses = ''

      if !list.empty?
        list.each { |s| uses << "#{s[key]}; " }
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
        charr.each do |line|
          if m = line.match(/^([A-Za-z]+): (.*)$/)
            self.parse_attr(m[1].downcase, m[2])
          end
        end
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
        self.type_key = self.pool.find_class_key(value)

      elsif title == 'trait'
        self.trait = value

      elsif title == 'proficiencies'
        self.profs = self.list_from_line(value)

      elsif title == 'spells'
        self.spells = self.list_from_line(value)

      elsif title == 'weapon'
        self.weapon = self.parse_weapon_str(value)

      elsif title == 'armor'
        self.armor = self.list_from_line(value).first

      elsif title == 'item'
        self.item = value

      elsif title == 'stats'
        self.stats = self.fill_stats(value.split(' '))

      elsif title == 'hp'
        self.hp = value

      elsif title == 'gp'
        self.gp = value

      else
        raise Exception.new("WTF: '#{title}', '#{value}'")
      end
    end



    def list_from_line( line = '', key = 'title', sep = ',' )
      ret = [ ]

      parts = line.split(sep)
      parts.each do |part|
        ret.push({ key => part.strip })
      end

      return ret
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

      return ret
    end


  end
end
