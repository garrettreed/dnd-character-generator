require 'yaml'


module DND
  class ResourcePool

    #
    # These methods name files for loading the character traits they
    # describe.
    #

    def self.alignments_file
      "sources/alignments.yaml"
    end

    def self.armors_file
      # "sources/armor/general.yaml"
      # "sources/armor/sci-fi.yaml"
      # "sources/armor/summer-camp.yaml"
      "sources/armor/home-alone.yaml"
    end

    def self.types_file
      # "sources/classes/general.yaml"
      # "sources/classes/sci-fi.yaml"
      # "sources/classes/summer-camp.yaml"
      "sources/classes/home-alone.yaml"
    end

    def self.items_file
      # "sources/items/items.yaml"
      # "sources/items/sci-fi.yaml"
      # "sources/items/summer-camp.yaml"
      "sources/items/home-alone.yaml"
    end

    def self.names_f_file
      # "sources/names/airtype_first.yaml"
      # "sources/names/general_first.yaml"
      "sources/names/summer-camp_first.yaml"
    end

    def self.names_l_file
      # "sources/names/airtype_lsst.yaml"
      "sources/names/general_last.yaml"
      # "sources/names/summer-camp_first.yaml"
    end

    def self.races_file
      # "sources/races/general.yaml"
      # "sources/races/sci-fi.yaml"
      # "sources/races/aliens.yaml"
      "sources/races/summer-camp.yaml"
    end

    def self.traits_file
      "sources/traits/general.yaml"
      # "sources/traits/summer-camp.yaml"
    end


    #
    # These methods point to file locations and will load the file
    # named in the parameter.
    #

    def self.proficiencies_file( ref = 'general' )
      "sources/proficiencies/#{ref}.yaml"
    end

    def self.spells_file( ref = 'wizard' )
      "sources/spells/#{ref}.yaml"
    end

    def self.weapons_file( ref = 'summer-camp' )
      # "sources/weapons/#{ref}.yaml"
      "sources/weapons/summer-camp.yaml"
    end


    #
    # These traits could depend on the character's race, type, etc.
    # So if an array is given, then filtering might occur on those
    # traits. If a string, then that file will be irrespective of
    # anything.
    #

    def self.weapons_files
      # %w{ exotic martial simple }
      # "sci-fi"
      "summer-camp"
    end

    def self.spell_files
      %w{ bard cleric druid paladin ranger wizard }
    end

    def self.proficiencies_files
      %w{ dwarf elf fighter general gnome halfling mage monk psionics rogue }
    end



    # These symbols name the various sub-pools that comprise the
    # Resource Pool. Methods in this class and instance must use
    # these names because they will be called dynamically. So like
    # `alignments_file`, `init_armors`, `load_types`, etc.
    def self.attrs
      [
        :alignments,
        :armors,
        :types,
        :items,
        :names_f,
        :names_l,
        :proficiencies,
        :races,
        :spells,
        :traits,
        :weapons,
      ]
    end


    # These name subpools/attributes that should be unique among the
    # characters -- while picking attributes, these will be filled
    # with entries, and those entries won't recur among the crew.
    # The structure of the subarrays is:
    # 0: The name of the `picked` attribute. It will be accessed via
    #   `@picked_{attr}`
    # 1: A symbol or an array.
    #   If a symbol, names the Character's relating attribute/method.
    #   If an array, must contain two symbol items:
    #   0: The item in the Pool's `attrs` that the value was picked from.
    #   1: The method name on the Character to access the value.
    def self.unique_attrs
      [
        # [:names, [:names_f, :names_l]],
        [:types, :type],
        [:weapons, :weapon],
        [:armors, :armor],
        [:traits, :trait],
        [:items, :item],
      ]
    end





    def initialize
      ResourcePool.attrs.each do |attr|
        # Define getters and setters.
        self.class.send :define_method, attr do
          self.instance_variable_get("@#{attr}")
        end

        self.class.send :define_method, "#{attr}=" do |val|
          self.instance_variable_set("@#{attr}", val)
        end

        # Initialize the attribute as an empty array.
        self.send("#{attr}=", [ ])
      end

      ResourcePool.unique_attrs.each do |_attr|
        attr = _attr[0]

        # Define getters and setters.
        self.class.send :define_method, "picked_#{attr}" do
          self.instance_variable_get("@picked_#{attr}")
        end

        self.class.send :define_method, "picked_#{attr}=" do |val|
          self.instance_variable_set("@picked_#{attr}", val)
        end

        # Initialize the attribute as an empty hash.
        self.send("picked_#{attr}=", { })
      end
    end


    def init_attr(attr, ref = nil)
      self.send("#{attr}=", self.load_attr(attr, ref))
    end


    def load_attr(attr, ref = nil)
      if (ref.nil?)
        return YAML.load_file(ResourcePool.send("#{attr}_file"))
      end

      list = YAML.load_file(ResourcePool.send("#{attr}_file", ref))
      if (list.is_a?(Hash))
        if (list.has_key?(ref))
          return list[ref]
        else
          return list[list.keys.sample]
        end
      else
        return list
      end
    end


    def check(attr, ref = nil)
      if (self.send(attr).empty?)
        self.init_attr(attr, ref)
      end
    end


    def pick(attr, ref = nil)
      self.check(attr, ref)

      list = self.send(attr)
      if (list.is_a?(Array))
        return list.sample
      elsif (list.is_a?(Hash))
        if ((!ref.nil?) && (list.has_key?(ref)))
          return list[ref].sample
        else
          return list[keys.sample].sample
        end
      else
        raise "Critical hit: to pick from a list, it must be an Array or a Hash."
      end
    end


    def record_if_needed(attr, val)
      if (self.is_storing_picked?(attr))
        self.add_to_picked(attr, val)
        self.delete_from_pool(attr, val)
      end
    end


    def is_storing_picked?(attr)
      return self.respond_to?("picked_#{attr}")
    end


    def has_been_picked?(attr, val)
      rec = self.send("picked_#{attr}")
      return rec.has_key?(val)
    end


    def add_to_picked(attr, val)
      rec = self.send("picked_#{attr}")
      rec[val] = true
    end


    def delete_from_pool(attr, val)
      # puts "DELETING #{val}\nFROM: #{self.send(attr)}"
      self.send(attr).delete(val)
      # puts "NOW:  #{self.send(attr)}"
    end


    # Pass this a Character. Any of those character's traits that
    # should be unique need to be deleted from the appropriate set.
    def remove_unique_attrs( char )
      ResourcePool.unique_attrs.each do |attr|
        if (self.is_storing_picked?(attr[0]))
          atr = attr[0]
          attr.slice(1, (attr.length - 1)).each do |attr|
            if (attr.is_a?(Array))
              self.add_to_picked(atr, char.send(attr[1]))
              self.delete_from_pool(attr[0], char.send(attr[1]))
            else
              self.add_to_picked(atr, char.send(attr))
              self.delete_from_pool(atr, char.send(attr))
            end
          end
        end
      end
    end


    # # To prevent duplicates, the generated names should be placed in
    # # the @names array and that should be checked when picking.
    # def init_names
    #   self.names_f = self.load_attr(:names_f)
    #   self.names_l = self.load_attr(:names_l)
    #   self.names = [ ]
    # end

    # def init_alignments
    #   self.alignments = YAML.load_file(ResourcePool.alignments_file)
    # end

    # def init_armors
    #   self.armors = YAML.load_file(ResourcePool.armor_file)
    # end

    # def init_types
    #   self.types = YAML.load_file(ResourcePool.types_file)
    # end

    # def init_items
    #   self.items = YAML.load_file(ResourcePool.items_file)
    # end

    # def init_races
    #   self.races = YAML.load_file(ResourcePool.races_file)
    # end

    # def init_traits
    #   self.traits = YAML.load_file(ResourcePool.traits_file)
    # end

    # def init_spells( ref = 'wizard' )
    #   self.spells = YAML.load_file(ResourcePool.spells_file(ref))
    # end

    # def init_proficiencies
    #   self.proficiencies = self.load_proficiencies
    # end

    # def init_weapons( ref = '' )
    #   self.weapons = self.load_weapons(ref)
    # end


    # def load_spells( ref = 'wizard' )
    #   return YAML.load_file(ResourcePool.spells_file(ref))
    # end

    # def load_proficiencies( ref = 'general' )
    #   return YAML.load_file(ResourcePool.proficiencies_file(ref))
    # end

    # def load_weapons( ref = '' )
    #   return YAML.load_file(ResourcePool.weapons_file(ref))
    # end



    def find_type_key( typename )
      self.check(:types)

      compare = typename.downcase
      key = nil

      self.types.each do |parent, children|
        if (children.is_a?(Hash))
          children.each { |n| key = parent if n.downcase == compare }
        end
      end

      return key
    end

  end
end
