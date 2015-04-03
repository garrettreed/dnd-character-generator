    # This was used when reading the character data from a file.
    # It's not currently being used but this could be a useful feature.
    # Add later?
    # def parse_attr( title, value )
    #   if title == 'name'
    #     self.name = value
    #   elsif title == 'alignment'
    #     self.alignment = value
    #   elsif title == 'race'
    #     self.race = value
    #   elsif title == 'class'
    #     self.type = value
    #   elsif title == 'trait'
    #     self.trait = value
    #   elsif title == 'proficiencies'
    #     self.profs = value
    #   elsif title == 'spells'
    #     self.spells = value
    #   elsif title == 'weapon'
    #     self.weapon = value
    #   elsif title == 'armor'
    #     self.armor = value
    #   elsif title == 'item'
    #     self.item = value
    #   elsif title == 'stats'
    #     self.stats = value.split(' ')
    #   elsif title == 'hp'
    #     self.hp = value
    #   elsif title == 'gp'
    #     self.gp = value
    #   else
    #     raise Exception.new "WTF: '#{title}', '#{value}'"
    #   end
    # end





        f = File.open Charsheets.file_to_read
        f.each do |line|
          line = line.chomp
          if line.empty?
            self.chars.push self.wrap_char
            if self.chars.count == 4
              self.write_file
              self.get_new_sheet
            else
              self.get_new_char
            end
          else
            self.parse_line line
          end
        end




    def parse_line( line )
      if m = line.match(/^([a-z]+): (.*)$/)
        self.char.parse_attr(m[1], m[2])
      end
    end
