require 'thor'

module F4R

  module CLI

    class SubCommandBase < Thor

      !check_unknown_options

      class_option :quiet, type: :boolean, aliases: '-q'
      class_option :debug, type: :boolean, aliases: '-d'
      class_option :verbose, type: :boolean, aliases: '-v'

      def self.banner(command, namespace = nil, subcommand = false)
        "#{basename} #{subcommand_prefix} #{command.usage}"
      end

      def self.subcommand_prefix
        self.name.
          gsub(%r{.*::}, '').
          gsub(%r{^[A-Z]}) { |match| match[0].downcase }.
          gsub(%r{[A-Z]}) { |match| "-#{match[0].downcase}" }
      end

    end

  end

end
