# D&D

This is a Ruby module for generating D&D characters. There's a little backstory behind why they're short of some things---they were designed for a [Dungeons & Debauchery][story] party, not a long-term, technically-complete D&D campaign. And they suit their purpose well.

To get started, just clone the repo. There are no external dependencies.

For four characters, run

    $ ./dnd.rb chars 4

Sample output:

    Name: India Kinkings
    Race: Halfling
    Class: Thief
    Alignment: Lawful good
    Weapon: Shuriken (5) 1d2
    Armor: Scale mail
    Proficiencies: Feign/Detect Sleep; Heat Protection; Origami
    Trait: Family killed by goblins
    Item: Four oxen
    Stats: 9 7 14 13 11 14
    HP: 19
    GP: 402

    Name: Ferdinand Danders
    Race: Jungle Elf
    Class: Wizard
    Alignment: Neutral evil
    Weapon: Longspear 1d8
    Armor: Studded leather
    Spells: Disguise Self; Detect Thoughts
    Proficiencies: Weather Sense; Planar Survival; Fire-Building
    Trait: Asthma
    Item: Quilt
    Stats: 18 6 17 17 13 17
    HP: 16
    GP: 389

    Name: Ray McBastard
    Race: Wood Elf
    Class: Sorcerer
    Alignment: True neutral
    Weapon: Light Mace 1d6
    Armor: Leather
    Spells: Bear's Endurance; Daze
    Proficiencies: Undead Lore; Smelting; Cartography
    Trait: Necrophiliac
    Item: Magical globe
    Stats: 9 16 13 15 18 13
    HP: 13
    GP: 385

    Name: Henri Mudussu
    Race: High Elf
    Class: Thief
    Alignment: Lawful evil
    Weapon: Bastard Sword 1d10
    Armor: Hide
    Proficiencies: Dyer; Basket Making; Camouflage
    Trait: Collects tea cups
    Item: Leg of turkey
    Stats: 11 10 7 9 7 18
    HP: 15
    GP: 428


To cherrypick four characters:

    $ ./dnd.rb chars -c 4


To get a sheet of four characters, run

    $ ./dnd.rb sheet 1

and you'll get an HTML file named `sheets/char-sheets-1.html`, which will look like [this][look]. You can then print that file to [a PDF][pdf], print that PDF to paper, chop that paper up, and you'll be good to go.

The module can also read characters from a file shaped like the above output:

    $ ./dnd.rb file chars-list.txt

And it will return an HTML file containing those characters.



## Known bugs and limitations

One: it won't check for existing files in `sheets/` before writing over them, so if you generate a sheet you want to keep, rename it.

Two: there are some simple rules for allowing a character race- and class-specific proficiencies and spells, but the rules pretty much stop there. There are no restrictions on classes for races, bonuses or limitations based on stats, no THAC0 or Saving Throws, etc. The module could easily be expanded to conform fully with official rules but I have little motivation to do that right now.





[story]: http://richardmavis.info/dungeons-debauchery
[look]: https://github.com/rmavis/dnd-character-generator/blob/master/sheets/char-sheets-1.html
[pdf]: http://richardmavis.info/misc/dnd/char-sheets-3.pdf
