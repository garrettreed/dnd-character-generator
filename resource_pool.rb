#!/usr/bin/env ruby

require 'yaml'


module DND
  class ResourcePool

    #
    # These methods name files for loading the character traits they
    # describe.
    #

    def self.alignments_file; "sources/alignments.yaml" end


    def self.armor_file; "sources/armor/general.yaml" end
    # def self.armor_file; "sources/armor/sci-fi.yaml" end


    def self.classes_file; "sources/classes/general.yaml" end
    # def self.classes_file; "sources/classes/sci-fi.yaml" end


    def self.items_file; "sources/items/items.yaml" end
    # def self.items_file; "sources/items/sci-fi.yaml" end


    def self.names_f_file; "sources/names/airtype_first.yaml" end
    def self.names_l_file; "sources/names/airtype_last.yaml" end
    # def self.names_f_file; "sources/names/general_first.yaml" end
    # def self.names_l_file; "sources/names/general_last.yaml" end


    def self.races_file; "sources/races/general.yaml" end
    # def self.races_file; "sources/races/sci-fi.yaml" end
    # def self.races_file; "sources/races/aliens.yaml" end


    def self.traits_file; "sources/traits/general.yaml" end



    #
    # These traits could depend on the character's race, class, etc.
    # So if an array is given, then filtering might occur on those
    # traits. If a string, then that file will be irrespective of
    # anything.
    #

    def self.spell_files
      %w{ bard cleric druid paladin ranger wizard }
    end

    def self.proficiencies_files
      %w{ dwarf elf fighter general gnome halfling mage monk psionics rogue }
    end

    def self.weapons_files
      %w{ exotic martial simple }
      # "sci-fi"
    end



    #
    # These methods point to file locations and will load the file
    # named in the parameter.
    #

    def self.spells_file( ref = 'wizard' )
      "sources/spells/#{ref}.yaml"
    end

    def self.proficiencies_file( ref = 'general' )
      "sources/proficiencies/#{ref}.yaml"
    end

    def self.weapons_file( ref = 'simple' )
      "sources/weapons/#{ref}.yaml"
    end





    def initialize
      @alignments = nil
      @armors = nil
      @classes = nil
      @items = nil
      @names = nil  # Holds the selected names.
      @names_f = nil
      @names_l = nil
      @proficiencies = nil
      @races = nil
      @spells = nil
      @traits = nil
      @weapons = nil
    end

    attr_accessor :alignments, :armors, :classes, :items, :names, :names_f, :names_l, :proficiencies, :races, :spells, :traits, :weapons



    # To prevent duplicates, the generated names should be placed in
    # the @names array and that should be checked when picking.
    def init_names
      n = self.load_names
      self.names_f = n[:f]
      self.names_l = n[:l]
      self.names = [ ]
    end

    def init_alignments
      self.alignments = self.load_alignments
    end

    def init_armors
      self.armors = self.load_armors
    end

    def init_classes
      self.classes = self.load_classes
    end

    def init_items
      self.items = self.load_items
    end

    def init_races
      self.races = self.load_races
    end

    def init_traits
      self.traits = self.load_traits
    end

    def init_spells( ref = 'wizard' )
      self.spells = self.load_spells
    end

    def init_proficiencies
      self.proficiencies = self.load_proficiencies
    end

    def init_weapons( ref = '' )
      self.weapons = self.load_weapons(ref)
    end



    def load_names
      return {
        :f => YAML.load_file(DND::ResourcePool.names_f_file),
        :l => YAML.load_file(DND::ResourcePool.names_l_file)
      }
    end

    def load_alignments
      return YAML.load_file(DND::ResourcePool.alignments_file)
    end

    def load_armors
      return YAML.load_file(DND::ResourcePool.armor_file)
    end

    def load_classes
      return YAML.load_file(DND::ResourcePool.classes_file)
    end

    def load_items
      return YAML.load_file(DND::ResourcePool.items_file)
    end

    def load_races
      return YAML.load_file(DND::ResourcePool.races_file)
    end

    def load_traits
      return YAML.load_file(DND::ResourcePool.traits_file)
    end

    def load_spells( ref = 'wizard' )
      return YAML.load_file(DND::ResourcePool.spells_file(ref))
    end

    def load_proficiencies( ref = 'general' )
      return YAML.load_file(DND::ResourcePool.proficiencies_file(ref))
    end

    def load_weapons( ref = '' )
      return YAML.load_file(DND::ResourcePool.weapons_file(ref))
    end



    def find_class_key( classname )
      self.init_classes if self.classes.nil?
      compare = classname.downcase
      key = nil

      self.classes.each do |parent, children|
        children.each { |n| key = parent if n.downcase == compare }
      end

      return key
    end



    # Pass this a Character. Any of those character's traits that
    # should be unique need to be deleted from the appropriate set.
    def remove_unique_attrs( char )
      self.names.push(char.name)
      self.traits.delete(char.trait)
    end

  end
end
