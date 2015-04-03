#!/usr/bin/env ruby


module DND
  class CharSheet


    def self.from_file( filename = DND::CharSheet.file_to_read )
      DND::CharSheet.new filename
    end



    def self.def_quant
      20
    end

    def self.file_to_read
      "chars-list.txt"
    end

    def self.file_to_write( n = 1 )
      "char-sheets-#{n}.html"
    end

    def self.block_joint
      "<br />\n<br />\n"
    end




    def initialize( ini )
      if ini.is_a? Integer
        @quant, @infile = ini, nil
      elsif ini.is_a? String
        @quant, @infile = nil, ini
      else
        raise Exception.new "Can't create new character sheet! Bad init param."
      end

      @crew, @char, @chars, @fcount = [ ], nil, [ ], 1
      @last_lines = 0
      self.make
    end

    attr_reader :quant, :infile
    attr_accessor :crew, :char, :chars, :fcount, :last_lines



    def get_new_sheet
      self.char, self.chars = nil, [ ]
    end


    def make
      self.get_new_sheet
      self.get_crew

      self.crew.each do |char|
        self.char = char
        self.chars.push self.wrap_char

        if self.chars.count == 4
          self.write_file
          self.get_new_sheet
        end
      end
    end



    def get_crew
      if self.infile.nil?
        self.crew = DND::Character.crew self.quant

      else
        lines = [ ]
        f = File.open self.infile
        f.each do |line|
          line = line.chomp
          if line.empty?
            chk = DND::Character.from_lines lines
            self.crew.push(chk) if chk.is_a? DND::Character
          else
            lines.push line
          end
        end
      end
    end



    def wrap_char
      self.last_lines = 6

      ret = <<HTML
<div class="block-cell">
	<div class="block-block">

		<div class="name">#{self.char.name}</div>

		<div class="vitals">
			<div class="alignment">#{self.char.alignment}</div>
			<div class="race">#{self.char.race}</div>
			<div class="class">#{self.char.type}</div>
		</div>

		<div class="stats-line">
			<div class="stat-block">
				<div class="stat-val">#{self.char.stats['str']}</div>
				<div class="stat-hdr">str</div>
			</div>
			<div class="stat-block">
				<div class="stat-val">#{self.char.stats['con']}</div>
				<div class="stat-hdr">con</div>
			</div>
			<div class="stat-block">
				<div class="stat-val">#{self.char.stats['agi']}</div>
				<div class="stat-hdr">agi</div>
			</div>
			<div class="stat-block">
				<div class="stat-val">#{self.char.stats['int']}</div>
				<div class="stat-hdr">int</div>
			</div>
			<div class="stat-block">
				<div class="stat-val">#{self.char.stats['wis']}</div>
				<div class="stat-hdr">wis</div>
			</div>
			<div class="stat-block" pad="right">
				<div class="stat-val">#{self.char.stats['cha']}</div>
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
			#{self.attr_block self.char.profs_str}
		</div>
HTML

      if !self.char.spells.empty?
        self.last_lines -= 1
        ret << <<HTML
		<div class="attrs-block">
			<img class="list-icon" id="magis-icon" src="icons/icon_26143/icon_26143.svg " />
			#{self.attr_block self.char.spells_str}
		</div>
HTML
      end

      ret << <<HTML
		<div class="attrs-block">
			<img class="list-icon" id="wpons-icon" src="icons/icon_1161/icon_1161.png" />
			#{self.attr_block self.char.weapon_str}
		</div>

		<div class="attrs-block">
			<img class="list-icon" id="armrs-icon" src="icons/icon_5826/icon_5826.png" />
			#{self.attr_block self.char.armor_str}
		</div>

		<div class="attrs-block">
			<img class="list-icon" id="items-icon" src="icons/icon_23677/icon_23677.png" />
			<p>#{self.char.item}</p>
HTML

      self.last_lines.times { ret << "<p>&nbsp;</p>" }

      ret << <<HTML
		</div>

	</div>
</div>
HTML

      return ret
    end



    def attr_block( attr = '' )
      attr = (attr.nil?) ? '' : attr
      ret, lim, len, loopd = '', 36, 0, 0

      while !attr.nil? and attr.length > 0
        if attr.length > lim
          chk = attr.slice(0..lim)
          len = chk.rindex(' ') || lim
        else
          chk, len = attr, attr.length
        end

        ret << "<p>#{chk.slice(0..len)}</p>"
        attr = attr.slice((len + 1)..attr.length)

        loopd += 1
      end

      self.last_lines -= (loopd - 1) if (loopd > 1)

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
				#{top.join(DND::CharSheet.block_joint)}
			</div>
			<div class="block-row">
				#{bot.join(DND::CharSheet.block_joint)}
			</div>
		</div>
	</body>
</html>
HTML

      f = File.write(DND::CharSheet.file_to_write(self.fcount), out)
      self.fcount += 1
    end

  end
end
