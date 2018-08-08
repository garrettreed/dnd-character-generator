# The Campaign class will `require` this one, so this won't need to
# `require` Campaign.
require_relative "numbers.rb"
require_relative "resource_pool.rb"

module DND
  class Character

    # Returns an array of characters.
    def self.crew( n = self.def_quant )
      set = [ ]
      pool = ResourcePool.new

      n.times do
        char = Character.new(pool, true)
        pool.remove_unique_attrs(char)
        set.push(char)
      end

      return set
    end


    # Returns the same as `crew` but prints the character and prompts
    # the user to keep or skip it before adding it to the crew.
    def self.select( n = self.def_quant )
      set = [ ]
      pool = ResourcePool.new

      while (set.length < n) do
        char = Character.new(pool, true)
        if (char.want_to_keep?([set.length, n]))
          pool.remove_unique_attrs(char)
          set.push(char)
        end
      end

      return set
    end


    # Receives an array of characters and prints them to a file.
    def self.to_file( chars )
      filename = "characters-#{chars.length}-#{Time.now.to_i}.txt"

      handle = File.new(filename, 'w')
      chars.each do |char|
        handle.puts(char.lines.join("\n"), "\n")
      end
      handle.close

      return filename
    end


    # Receives a filename, reads it, returns an array of characters.
    def self.from_file( filename )
      f = File.open(filename)
      chars = [ ]
      lines = [ ]
      working = nil

      f.each do |line|
        line = line.chomp

        if line.empty?
          chk = self.from_lines(lines)
          if chk.is_a?(Character)
            chars.push(chk)
          end
          working = nil
          lines = [ ]
        else
          working = true
          lines.push(line)
        end
      end

      if working
        chk = self.from_lines(lines)
        if chk.is_a?(Character)
          chars.push(chk)
        end
      end

      return chars
    end


    # Pass this an array of key-value pairs and get a fully-formed
    # Character in return.
    def self.from_lines( charr = [ ] )
      pool = ResourcePool.new
      char = Character.new(nil, nil)
      char.read_arr(charr, pool)
      return char
    end


    def self.single_trait( act, n )
      ref = Campaign.acts_and_actions[act]
      pool = ResourcePool.new
      set = [ ]

      n.times do
        char = Character.new(pool, nil)
        val = char.send(ref[:pick], pool)
        char.send("#{ref[:attr]}=", val)
        pool.remove_unique_attrs(char)
        set.push(val)
      end

      return set
    end



    def self.def_quant
      1
    end

    def self.quant_spells
      2
    end

    def self.quant_profs
      3
    end



    def initialize( pool, autogen = nil )
      @alignment = ''
      @armor = ''
      @item = ''
      @name_f = ''
      @name_l = ''
      @race = ''
      @trait = ''
      @type = ''
      @type_key = ''
      @weapon = ''

      @profs = [ ]
      @spells = [ ]

      @gp = 0
      @hp = 0

      if autogen
        if (pool.is_a?(ResourcePool))
          self.gen(pool)
        else
          raise "Can't generate Character without a ResourcePool."
        end
      end
    end

    attr_accessor :alignment, :armor, :gp, :hp, :item, :name_f, :name_l, :profs, :race, :spells, :stats, :trait, :type, :type_key, :weapon


    def gen( pool )
      self.alignment = self.pick_from_pool(pool, :alignments)
      self.item = self.pick_from_pool(pool, :items)
      self.race = self.pick_from_pool(pool, :races)
      self.trait = self.pick_from_pool(pool, :traits)

      self.name_f = self.pick_name_f(pool)
      self.name_l = self.pick_name_l(pool)
      self.type = self.pick_type(pool)
      self.armor = self.pick_armor(pool)
      self.weapon = self.pick_weapon(pool)
      self.profs = self.pick_proficiencies(pool)

      # #HERE
      # if (self.gets_spells?)
      #   self.spells = self.pick_spells(pool)
      # end

      # These generate numbers.
      self.stats = self.pick_stats
      self.hp = self.pick_hp
      self.gp = self.pick_gp
    end



    #
    # These characteristics don't depend on others.
    #

    def pick_from_pool(pool, attr, ref = nil)
      # puts "Picking #{attr}"
      return pool.pick(attr, ref)
    end


    def pick_name_f( pool )
      return pool.pick(:names_f)
      # return "#{pool.pick(:names_f)} #{pool.pick(:names_l)}"
    end

    def pick_name_l( pool )
      return pool.pick(:names_l)
      # return "#{pool.pick(:names_f)} #{pool.pick(:names_l)}"
    end


    def pick_type( pool )
      pool.check(:types)

      if (pool.types.is_a?(Hash))
        self.type_key = pool.types.keys.sample
        return pool.types[self.type_key].sample
      else
        return pool.pick(:types)
      end
    end



    #
    # These attributes must be picked after the character's type.
    # Note that they rely on the `type_key`, which will be set in
    # `pick_type` if necessary.
    #

    def pick_armor( pool )
      pool.check(:armors)

      if (self.type_key.nil?)
        return pool.pick(:armors)
      elsif (self.is_type?('fighter'))
        return pool.pick(:armors, 'heavy')
      elsif (self.is_type?('rogue'))
        return pool.pick(:armors, 'medium')
      else
        return pool.pick(:armors, 'light')
      end
    end


    def pick_weapon( pool )
      # This will be a string or an array.
      res = ResourcePool.weapons_files

      if (res.is_a?(String))
        return pool.pick(:weapons, res)
      elsif (self.type_key.nil?)
        return pool.pick(:weapons, res.sample)
      elsif (self.is_type?('fighter'))
        if (self.is_type?('ranger'))
          return pool.pick(:weapons, 'simple')
        else
          return pool.pick(:weapons, 'martial')
        end
      elsif (self.is_type?('rogue'))
        return pool.pick(:weapons, 'exotic')
      else
        return pool.pick(:weapons, 'simple')
      end
    end


    def pick_proficiencies( pool, quant = Character.quant_profs )
      res = ResourcePool.proficiencies_files

      if (res.is_a?(String))
        profs = pool.load_attr(:proficiencies, res)
        return profs.sample(quant)
      end

      profs = [ ]

      profs.push(pool.load_attr(:proficiencies, 'general'))
      %w{ dwarf elf gnome halfling }.each do |race|
        if (self.is_race?(race))
          profs.push(pool.load_attr(:proficiencies, race))
        end
      end
      %w{ fighter mage monk rogue }.each do |_type|
        if (self.is_type?(_type))
          profs.push(pool.load_attr(:proficiencies, _type))
        end
      end

      return profs.flatten.sample(quant)
    end


    # ATTENTION  #HERE
    # In its revised form, `pick_spells` will end up looking pretty
    # similar to `pick_proficiencies`.
    # def pick_spells( pool, quant = Character.quant_spells )
    #   pool.init_spells if pool.spells.nil?

    #   spells = [ ]

    #   # This could be expanded but it will work for entry-level characters.
    #   levels = %w{ level0 level1 level2 }

    #   # The general spells.
    #   levels.each do |level|
    #     if pool.spells.has_key?(level)
    #       chk_sp = pool.spells[level].clone

    #       # Necromancer spells are special.
    #       chk_sp.delete('necro') if !self.is_type?('necro')
    #       chk_sp.each { |key,arr| spells.push(arr) }
    #     end
    #   end

    #   # The type-based spells.
    #   %w{ bard cleric druid paladin ranger }.each do |closs|
    #     if self.is_type?(closs)
    #       chk_sp = pool.init_spells(closs)

    #       levels.each do |level|
    #         spells.push(chk_sp[level]) if chk_sp.has_key?(level)
    #       end
    #     end
    #   end

    #   return spells.flatten.sample(quant)
    # end



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

      while ((!bonus.nil?) && (bonus > 0))
        stat_key = ret.keys.sample
        stat_val = ret[stat_key]

        bonu = rand(1..bonus)
        if ((stat_val + bonu) > 18)
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
      %w{ mage monk Bard }.each { |chk| ret = true if self.is_type?(chk) }
      return ret
    end


    def is_race?( chk = '' )
      return self.race.downcase.include?(chk)
    end

    def is_type?( chk = '' )
      return ((self.type_key == chk) || (self.type.downcase.include?(chk)))
    end

    def is_alignment?( chk = '' )
      return self.alignment.downcase.include?(chk)
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
        "First name: #{self.name_f}",
        "Last name: #{self.name_l}",
        "Race: #{self.race}",
        "Class: #{self.type}",
        "Alignment: #{self.alignment}",
        "Weapon: #{self.weapon_str}",
        "Armor: #{self.armor_str}"
      ]

      if (!self.spells.empty?)
        lines.push("Spells: #{self.str_from_list(self.spells)}")
      end

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

    def read_arr( charr = [ ], pool )
      charr.each do |line|
        if m = line.match(/^([A-Za-z ]+): (.*)$/)
          self.parse_attr(pool, m[1].downcase, m[2])
        end
      end
    end


    def parse_attr( pool, title, value )
      if title == 'first name'
        self.name_f = value

      elsif title == 'last name'
          self.name_l = value

      elsif title == 'alignment'
        self.alignment = value

      elsif title == 'race'
        self.race = value

      elsif ((title == 'type') || (title == 'class'))
        self.type = value
        self.type_key = pool.find_type_key(value)

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
