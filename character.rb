#!/usr/bin/env ruby


module DND
  class Character


    def initialize
      @name, @alignment, @race, @type, @trait, @profs, @spells, @weapon, @armor, @item, @stats, @hp, @gp = nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil
    end

    attr_accessor :name, :alignment, :race, :type, :trait, :profs, :spells, :weapon, :armor, :item, :stats, :hp, :gp


    def parse_attr( title, value )
      if title == 'name'
        self.name = value
      elsif title == 'alignment'
        self.alignment = value
      elsif title == 'race'
        self.race = value
      elsif title == 'class'
        self.type = value
      elsif title == 'trait'
        self.trait = value
      elsif title == 'proficiencies'
        self.profs = value
      elsif title == 'spells'
        self.spells = value
      elsif title == 'weapon'
        self.weapon = value
      elsif title == 'armor'
        self.armor = value
      elsif title == 'item'
        self.item = value
      elsif title == 'stats'
        self.stats = value.split(' ')
      elsif title == 'hp'
        self.hp = value
      elsif title == 'gp'
        self.gp = value
      else
        raise Exception.new "WTF: '#{title}', '#{value}'"
      end
    end

  end
end
