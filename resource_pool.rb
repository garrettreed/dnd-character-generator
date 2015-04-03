#!/usr/bin/env ruby

require 'yaml'


module DND
  class ResourcePool

    def self.alignments_file; "sources/alignments.yaml" end
    def self.armor_file; "sources/armor.yaml" end
    def self.classes_file; "sources/classes.yaml" end
    def self.names_file; "sources/names_2.yaml" end
    def self.items_file; "sources/items_2.yaml" end
    def self.races_file; "sources/races.yaml" end
    def self.traits_file; "sources/traits.yaml" end


    def self.spells_file( ref = '' )
      "sources/spells/#{ref}.yaml"
    end

    def self.proficiencies_file( ref = '' )
      "sources/proficiencies/#{ref}.yaml"
    end

    def self.weapons_file( ref = '' )
      "sources/weapons/#{ref}.yaml"
    end


    def self.spell_files
      %w{ bard cleric druid paladin ranger wizard }
    end

    def self.proficiencies_files
      %w{ dwarf elf fighter general gnome halfling mage monk psionics rogue }
    end

    def self.weapons_files
      %w{ exotic martial simple }
    end




    def initialize
      @alignments, @armors, @classes, @names, @items, @races, @traits, @spells, @proficiencies, @weapons = nil, nil, nil, nil, nil, nil, nil, nil, nil, nil
    end

    attr_accessor :alignments, :armors, :classes, :names, :items, :races, :traits, :spells, :proficiencies, :weapons



    def load_alignments
      self.alignments = YAML.load_file(DND::ResourcePool.alignments_file)
    end

    def load_armors
      self.armors = YAML.load_file(DND::ResourcePool.armor_file)
    end

    def load_classes
      self.classes = YAML.load_file(DND::ResourcePool.classes_file)
    end

    def load_names
      self.names = YAML.load_file(DND::ResourcePool.names_file)
    end

    def load_items
      self.items = YAML.load_file(DND::ResourcePool.items_file)
    end

    def load_races
      self.races = YAML.load_file(DND::ResourcePool.races_file)
    end

    def load_traits
      self.traits = YAML.load_file(DND::ResourcePool.traits_file)
    end


    def load_spells( ref = "wizard" )
      self.spells = YAML.load_file(DND::ResourcePool.spells_file(ref))
    end

    def load_proficiencies( ref = "general" )
      self.proficiencies = YAML.load_file(DND::ResourcePool.proficiencies_file(ref))
    end

    def load_weapons( ref = "general" )
      self.weapons = YAML.load_file(DND::ResourcePool.weapons_file(ref))
    end

  end
end
