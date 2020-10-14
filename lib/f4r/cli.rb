require 'thor'
require 'f4r'
require 'f4r/cli/export'
require 'f4r/cli/activity'

module F4R

  module CLI

    class App < Thor

      package_name 'F4R CLI'

      ENV['THOR_COLUMNS'] = '120'

      desc 'version', 'Show version'
      def version
        say "F4R-CLI: #{VERSION} (F4R: #{F4R::VERSION})"
      end

      desc 'help [COMMAND]', 'Describe commands or a specific command'
      def help(meth = nil)
        super
        unless meth
          say 'To learn more or to contribute, please see github.com/jpablobr/f4r-cli'
        end
      end

      desc 'export [FILE] [OPTIONS]', 'FIT to CSV/CSV to FIT export'
      subcommand 'export', Export

      desc 'activity [FILE] [OPTIONS]', 'Show/Edit activity'
      subcommand 'activity', Activity
    end

  end

end
