#!/usr/bin/ruby


class Charsheets

  def self.file_to_read
    "chars-list.txt"
  end


  def self.file_to_write( n = 1 )
    "char-sheet-#{n}.html"
  end


  def self.block_joint
    "<br />\n<br />\n"
  end


  def self.main
    x = Charsheets.new
    x.main
  end



  def initialize
    @char, @chars, @fcount = nil, [ ], 1
  end

  attr_accessor :char, :chars, :fcount


  def get_new_char
    self.char = Character.new
  end


  def main
    self.get_new_char
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
  end


  def get_new_sheet
    self.chars = [ ]
    self.get_new_char
  end




  def parse_line( line )
    if m = line.match(/^([a-z]+): (.*)$/)
      self.char.parse_attr(m[1], m[2])
    end
  end



  def wrap_char
    ret = <<HTML
<div class="block-cell">
	<div class="block-block">

		<div class="name">#{self.char.name}</div>

		<div class="vitals">
			<div class="alignment">#{self.char.alignment}</div>
			<div class="race">#{self.char.race}</div>
			<div class="class">#{self.char.class}</div>
		</div>

		<div class="stats-line">
			<div class="stat-block">
				<div class="stat-val">#{self.char.stats[0]}</div>
				<div class="stat-hdr">str</div>
			</div>
			<div class="stat-block">
				<div class="stat-val">#{self.char.stats[1]}</div>
				<div class="stat-hdr">con</div>
			</div>
			<div class="stat-block">
				<div class="stat-val">#{self.char.stats[2]}</div>
				<div class="stat-hdr">agi</div>
			</div>
			<div class="stat-block">
				<div class="stat-val">#{self.char.stats[3]}</div>
				<div class="stat-hdr">int</div>
			</div>
			<div class="stat-block">
				<div class="stat-val">#{self.char.stats[4]}</div>
				<div class="stat-hdr">wis</div>
			</div>
			<div class="stat-block" pad="right">
				<div class="stat-val">#{self.char.stats[5]}</div>
				<div class="stat-hdr">cha</div>
			</div>
			<div class="stat-block">
				<div class="stat-val">#{self.char.hp}</div>
				<div class="stat-hdr">hp</div>
			</div>
			<div class="stat-block">
				<div class="stat-val">#{self.char.gp}</div>
				<div class="stat-hdr">gp</div>
			</div>
		</div>

		<div class="attrs-block">
			<img class="list-icon" id="persn-icon" src="icons/icon_43149/icon_43149.svg" />
			#{self.attr_block self.char.trait}
		</div>

		<div class="attrs-block">
			<img class="list-icon" id="profs-icon" src="icons/icon_2672/icon_2672.png" />
			#{self.attr_block self.char.profs}
		</div>
HTML

    if self.char.spells
      ret << <<HTML
		<div class="attrs-block">
			<img class="list-icon" id="magis-icon" src="icons/icon_26143/icon_26143.svg " />
			#{self.attr_block self.char.spells}
		</div>
HTML
    end

    ret << <<HTML
		<div class="attrs-block">
			<img class="list-icon" id="wpons-icon" src="icons/icon_1161/icon_1161.png" />
			#{self.attr_block self.char.weapon}
		</div>

		<div class="attrs-block">
			<img class="list-icon" id="armrs-icon" src="icons/icon_5826/icon_5826.png" />
			#{self.attr_block self.char.armor}
		</div>

		<div class="attrs-block">
			<img class="list-icon" id="items-icon" src="icons/icon_23677/icon_23677.png" />
			<p>#{self.char.item}</p>
			<hr />
			<hr />
			<hr />
			<hr />
		</div>

	</div>
</div>
HTML

    return ret
  end



  def attr_block( attr )
    attr = attr.nil? ? '' : attr
    ret = "<p>#{attr}</p><hr />"
    ret << "<hr />" if attr.length > 37
    return ret
  end



  def write_file
    top, bot = self.chars.slice(0,2), self.chars.slice(2,2)

    out = <<HTML
<!DOCTYPE html>
<html lang="en">
  <head>
		<link rel="stylesheet" type="text/css" href="styles.css" />
  </head>

  <body>
		<div id="carapace">
			<div class="block-row">
				#{top.join(Charsheets.block_joint)}
			</div>
			<div class="block-row">
				#{bot.join(Charsheets.block_joint)}
			</div>
		</div>
	</body>
</html>
HTML

    f = File.write(Charsheets.file_to_write(self.fcount), out)
    self.fcount += 1
  end

end




class Character

  def initialize
@name, @alignment, @race, @class, @trait, @profs, @spells, @weapon, @armor, @item, @stats, @hp, @gp = nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil
  end

  attr_accessor :name, :alignment, :race, :class, :trait, :profs, :spells, :weapon, :armor, :item, :stats, :hp, :gp


  def parse_attr( title, value )
    if title == 'name'
      self.name = value
    elsif title == 'alignment'
      self.alignment = value
    elsif title == 'race'
      self.race = value
    elsif title == 'class'
      self.class = value
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





class Numbers

  def initialize( args = [ ] )
  end

  attr_reader :args
  attr_accessor :numbers


  def numbers( n = 6, lim = 18, bas = 6 )
    ret = [ ]
    n.times { ret.push rand(bas..lim) }
    return ret
  end

end


# n = Numbers.new
# puts n.numbers(6, 18, 6).join(' ')
# puts n.numbers(1, 20, 10).join(' ')
# puts n.numbers(1, 300, 0).join(' ')

Charsheets.main


