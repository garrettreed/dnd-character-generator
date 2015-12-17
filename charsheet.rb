#!/usr/bin/env ruby


module DND
  class CharSheet


    def self.from_file( filename = DND::CharSheet.file_to_read )
      DND::CharSheet.new(filename)
    end



    def self.def_quant
      1
    end

    def self.chars_per_sheet
      4
    end

    def self.file_to_read
      "chars-list.txt"
    end

    def self.dir_to_write
      "sheets"
    end

    def self.file_to_write( n = 1 )
      "#{DND::CharSheet.dir_to_write}/char-sheets-#{n}.html"
    end

    def self.block_joint
      "<br />\n<br />\n"
    end


    def self.dir_ok?
      if Dir.exist?(DND::CharSheet.dir_to_write)
        return true
      else
        return nil
      end
    end


    def self.make_dir!
      Dir.mkdir(DND::CharSheet.dir_to_write)
    end




    def initialize( ini )
      if ini.is_a?(Integer)
        crew = DND::Character.crew(ini * DND::CharSheet.chars_per_sheet)
      elsif ini.is_a?(String)
        crew = DND::Character.from_file(ini)
      else
        raise Exception.new("Can't create new character sheet! Bad init param.")
      end

      per = DND::CharSheet.chars_per_sheet
      rem = crew.length.divmod(per)
      x = 0

      if rem[0] == 0
        x = per - crew.length
      elsif (rem[0] > 0) && (rem[1] > 0)
        x = per - rem[1]
      end

      if x > 0
        puts "Adding #{x} characters to fill the sheet."
        crew.concat(DND::Character.crew(x))
      end

      @last_lines = 0

      self.make(crew)
    end


    attr_accessor :last_lines


    def make( crew )
      chars = [ ]
      file_count = 1

      crew.each do |char|
        chars.push(self.wrap_char(char))

        if chars.count == 4
          file_count = self.write_file(chars, file_count)
          chars = [ ]
        end
      end
    end



    def wrap_char( char )
      self.last_lines = 6

      ret = <<HTML
<div class="block-cell">
	<div class="block-block">

		<div class="name">#{char.name}</div>

		<div class="vitals">
			<div class="alignment">#{char.alignment}</div>
			<div class="race">#{char.race}</div>
			<div class="class">#{char.type}</div>
		</div>

		<div class="stats-line">
			<div class="stat-block">
				<div class="stat-val">#{char.stats['str']}</div>
				<div class="stat-hdr">str</div>
			</div>
			<div class="stat-block">
				<div class="stat-val">#{char.stats['con']}</div>
				<div class="stat-hdr">con</div>
			</div>
			<div class="stat-block">
				<div class="stat-val">#{char.stats['agi']}</div>
				<div class="stat-hdr">agi</div>
			</div>
			<div class="stat-block">
				<div class="stat-val">#{char.stats['int']}</div>
				<div class="stat-hdr">int</div>
			</div>
			<div class="stat-block">
				<div class="stat-val">#{char.stats['wis']}</div>
				<div class="stat-hdr">wis</div>
			</div>
			<div class="stat-block" pad="right">
				<div class="stat-val">#{char.stats['cha']}</div>
				<div class="stat-hdr">cha</div>
			</div>
			<div class="stat-block">
				<div class="stat-val">#{char.hp}</div>
				<div class="stat-hdr">hp</div>
			</div>
			<div class="stat-block">
				<div class="stat-val">#{char.gp}</div>
				<div class="stat-hdr">gp</div>
			</div>
		</div>

		<div class="attrs-block">
			<img class="list-icon" id="persn-icon" src="../icons/icon_43149/icon_43149.svg" />
			#{self.attr_block(char.trait)}
		</div>

		<div class="attrs-block">
			<img class="list-icon" id="profs-icon" src="../icons/icon_2672/icon_2672.png" />
			#{self.attr_block(char.str_from_list(char.profs))}
		</div>
HTML

      if !char.spells.empty?
        self.last_lines -= 1
        ret << <<HTML
		<div class="attrs-block">
			<img class="list-icon" id="magis-icon" src="../icons/icon_26143/icon_26143.svg " />
			#{self.attr_block(char.str_from_list(char.spells))}
		</div>
HTML
      end

      ret << <<HTML
		<div class="attrs-block">
			<img class="list-icon" id="wpons-icon" src="../icons/icon_1161/icon_1161.png" />
			#{self.attr_block(char.weapon_str)}
		</div>

		<div class="attrs-block">
			<img class="list-icon" id="armrs-icon" src="../icons/icon_5826/icon_5826.png" />
			#{self.attr_block(char.armor_str)}
		</div>

		<div class="attrs-block">
			<img class="list-icon" id="items-icon" src="../icons/icon_23677/icon_23677.png" />
			<p>#{char.item}</p>
HTML

      self.last_lines.times { ret << "<p>&nbsp;</p>" }

      ret << <<HTML
		</div>

	</div>
</div>
HTML

      return ret
    end



    def attr_block( attr )
      ret = ''
      lim = 36
      len = 0
      loops = 0

      while (!attr.nil?) && (attr.length > 0)
        if attr.length > lim
          chk = attr.slice(0..lim)
          len = chk.rindex(' ') || lim
        else
          chk = attr
          len = attr.length
        end

        ret << "<p>#{chk.slice(0..len)}</p>"
        attr = attr.slice((len + 1)..attr.length)

        loops += 1
      end

      self.last_lines -= (loops - 1) if (loops > 1)

      return ret
    end



    def write_file( chars, count )
      DND::CharSheet.make_dir! if !DND::CharSheet.dir_ok?
      top, bot = chars.slice(0,2), chars.slice(2,2)

      out = <<HTML
<!DOCTYPE html>
<html lang="en">
  <head>
		<link rel="stylesheet" type="text/css" href="../styles.css" />
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

      f = File.write(DND::CharSheet.file_to_write(count), out)

      return (count += 1)
    end

  end
end
