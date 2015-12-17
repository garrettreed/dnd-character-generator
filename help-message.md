# Help

This D&D module takes commands in this shape:
    $ ./dnd.rb {command} [flag] [quantity]

The command is required, the flag and quantity are both optional.



## Generating characters

This generates four characters and writes the result to `stdout`:
    $ ./dnd.rb character 4

This will present you with a character, which you can choose to keep or skip. After you've selected 4, they'll be written to a file in the same directory as `dnd.rb`.
    $ ./dnd.rb character -c 4

The `-c` is short for "cherrypick".



## Generating character sheets

This generates 10 character sheets and writes HTML files to `sheets/`:
    $ ./dnd.rb sheets 10

This reads a file of character information (say the output from `./dnd.rb character 4`) and writes HTML files to `sheets/`:
    $ ./dnd.rb file {filename}

The filename will look something like `characters-4-1450325540.txt`.



## Generating random stuff

To generate `stats`, `names`, `races`, etc., run something like:
    $ ./dnd.rb {thing you want} {how many you want}

The result will be written to `stdout`.
