# F4R::CLI

Initial disclaimer: This is still raw like :sushi: so haters to the left!

Command line interface for the [F4R library](https://github.com/jpablobr/f4r).

Allows for FIT binary files to be read, written and edited.

## Installation

    $ gem install f4r-cli

## Usage

Each main command (i.e., `activity` and `export`) and their sub-commands have their own `help` sub-command for documentation, usage and examples.

### Export

The export command can be seen more as an enhanced dump for reading and writing FIT binary files. As such, the user should properly understand the consequences of the edits given the way the field interact with each other and, also, taking into account their specific type and size specification (See FIT SDK documentation). A generated FIT file can be valid locally (against the FIT SDK) but not against Garmin or other FIT parsers. Different parsers might require different field interactions (between associated fields) specific to their own app implementations, so regardless of a FIT file being FIT SDK valid, it might still not work with them.

#### `export`:

    $ f4r help export  

    Export commands:
      f4r export help [COMMAND]           # Describe subcommands or one specific subcommand
      f4r export to-csv [FILE --options]  # FIT binary to CSV
      f4r export to-fit [FILE --options]  # CSV to FIT binary

    Options:
      -q, [--quiet], [--no-quiet]      
      -d, [--debug], [--no-debug]      
      -v, [--verbose], [--no-verbose]

#### `--to-csv`:

    $ f4r export help to-csv 

    Usage:
      f4r export to-csv [FILE --options]

    Options:
      -o, [--output-file=OUTPUT_FILE]                          # Output file
      -o, [--source-fit-file=SOURCE_FIT_FILE]                  # Source FIT file for edits
      -u, [--ignore-undocumented], [--no-ignore-undocumented]  # Ignore undocumented fields
      -g, [--ignore-guesses], [--no-ignore-guesses]            # Ignore guessed fields
      -n, [--ignore-null], [--no-ignore-null]                  # Ignore fields with null values
      -c, [--color], [--no-color]                              # Enable colour output
      -q, [--quiet], [--no-quiet]                              
      -d, [--debug], [--no-debug]                              
      -v, [--verbose], [--no-verbose]                          

    Description:
      Example usage:

      $ f4r to-csv activity.fit --output-file=activity.csv

#### `--to-fit`:

    $ f4r export help to-fit
    
    Usage:
      f4r export to-fit [FILE --options]

    Options:
      -o, [--output-file=OUTPUT_FILE]  # Output file
      -c, [--color], [--no-color]      # Enable colour output
      -q, [--quiet], [--no-quiet]      
      -d, [--debug], [--no-debug]      
      -v, [--verbose], [--no-verbose]  

    Description:
      Example usage:

      $ f4r to-fit activity.csv --output-file=activity.fit

### Activity

The `activity` command allows to view/edit a specific sport activity. It converts/translate fields to a more human readable format and the data is filtered and formatted specifically for the sport, which helps to be able to edit a sport more accurately and with a bigger change of being in the right format for the different FIT parsers.

#### `activity`:

    $ f4r help activity  

    Activity commands:
      f4r activity help [COMMAND]           # Describe subcommands or one specific subcommand
      f4r activity to-csv [FILE --options]  # FIT binary to CSV
      f4r activity to-fit [FILE --options]  # CSV to FIT binary

    Options:
      -q, [--quiet], [--no-quiet]      
      -d, [--debug], [--no-debug]      
      -v, [--verbose], [--no-verbose]

#### `--to-csv`:

    $ f4r activity help to-csv

    Usage:
      f4r activity to-csv [FILE --options]

    Options:
      -o, [--output-file=OUTPUT_FILE]  # Output CSV file
      -c, [--color], [--no-color]      # Enable colour output
      -q, [--quiet], [--no-quiet]      
      -d, [--debug], [--no-debug]      
      -v, [--verbose], [--no-verbose]  

    Description:
      Example usage:

      $ f4r to-csv activity.fit --output-file=activity.csv

#### `--to-fit`:

    $ f4r activity help to-fit

    Usage:
      f4r activity to-fit [FILE --options]

    Options:
      -c, [--color], [--no-color]              # Enable colour output
      -o, [--output-file=OUTPUT_FILE]          # Output FIT file
      -o, [--source-fit-file=SOURCE_FIT_FILE]  # Source FIT file (file to be edited)
      -q, [--quiet], [--no-quiet]              
      -d, [--debug], [--no-debug]              
      -v, [--verbose], [--no-verbose]          

    Description:
      Example usage:

      $ f4r activity to-fit activity.csv --output-file=activity.fit

## Limitations

- ATM the `activity` command only supports Lap Swim activities. (PRs for more welcome!) 

## Contributing

Bug reports and pull requests are welcome.

... More to come.

## License

TBA
