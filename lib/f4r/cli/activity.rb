require 'f4r/cli/sub_command_base'
require 'f4r/cli/sport/lap_swim'

module F4R

  module CLI

    class Activity < SubCommandBase

      package_name 'Activity'

      desc 'to-csv [FILE --options]', 'FIT binary to CSV'
      long_desc "
      Example usage:\n
      $ f4r activity to-csv activity.fit --output-file=activity.csv
      "
      method_option :output_file,
        type: :string,
        aliases: '-o',
        required: false,
        desc: 'Output CSV file'
      method_option :color,
        type: :boolean,
        aliases: '-c',
        required: false,
        desc: 'Enable colour output'
      def to_csv(fit_file)
        ActivityConverter.new(fit_file, options).to_csv
      end

      desc 'to-fit [FILE --options]', 'CSV to FIT binary'
      long_desc "
      Example usage:\n
      $ f4r activity to-fit activity.csv --output-file=activity.fit
      "
      method_option :color,
        type: :boolean,
        aliases: '-c',
        required: false,
        desc: 'Enable colour output'
      method_option :output_file,
        type: :string,
        aliases: '-o',
        required: false,
        desc: 'Output FIT file'
      method_option :source_fit_file,
        type: :string,
        aliases: '-s',
        required: true,
        desc: 'Source FIT file (file to be edited)'
      def to_fit(csv_file)
        ActivityConverter.new(csv_file, options).to_fit
      end

      class ActivityConverter
        def initialize(file, options)
          @file = file
          @options = options

          case
          when options.quiet?
            F4R::Log.level = 6
          when options.verbose?
            F4R::Log.level = :info
          when options.debug?
            F4R::Log.level = :debug
          end

          if options.color?
            F4R::Log.color = true
          end

          if options.source_fit_file
            @source_fit_file = options.source_fit_file
          end
        end

        def to_csv
          F4R::CLI::Sport::LapSwim.new(get_records(@file), @options).to_csv
        end

        def to_fit
          F4R::CLI::Sport::LapSwim.new(get_records(@source_fit_file), @options).to_fit(@file)
        end

        private

        def get_records(source_fit_file)
          F4R::decode(source_fit_file).records.inject([]) do |r, record|
            record[:fields].each { |_,f| f[:definition] = f[:definition].snapshot }
            r << record;r
          end
        end

      end

    end

  end

end
