require 'f4r/cli/converters'
require 'f4r/cli/sub_command_base'

module F4R

  module CLI

    class Export < SubCommandBase

      package_name 'Export'

      desc 'to-csv [FILE --options]', 'FIT binary to CSV'
      long_desc "
      Example usage:\n
      $ f4r to-csv activity.fit --output-file=activity.csv
      "

      method_option :output_file,
        type: :string,
        aliases: '-o',
        required: false,
        desc: 'Output file'
      method_option :ignore_undocumented,
        type: :boolean,
        aliases: '-u',
        required: false,
        desc: 'Ignore undocumented fields'
      method_option :ignore_guessed,
        type: :boolean,
        aliases: '-g',
        required: false,
        desc: 'Ignore guessed fields'
      method_option :ignore_null,
        type: :boolean,
        aliases: '-n',
        required: false,
        desc: 'Ignore fields with null values'
      method_option :color,
        type: :boolean,
        aliases: '-c',
        required: false,
        desc: 'Enable colour output'

      def to_csv(file)
        CSVConverter.new(file, options).to_csv
      end

      desc 'to-fit [FILE --options]', 'CSV to FIT binary'
      long_desc "
      Example usage:\n
      $ f4r to-fit activity.csv --output-file=activity.fit
      "
      method_option :output_file,
        type: :string,
        aliases: '-o',
        required: false,
        desc: 'Output file'
      method_option :color,
        type: :boolean,
        aliases: '-c',
        required: false,
        desc: 'Enable colour output'
      method_option :source_fit_file,
        type: :string,
        aliases: '-o',
        required: false,
        desc: 'Source FIT file for edits'

      def to_fit(file)
        CSVConverter.new(file, options).to_fit
      end

      class CSVConverter
        include Converters

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

          if options.output_file
            @output_file = options.output_file
          end

          if options.source_fit_file
            @source_fit_file = options.source_fit_file
          end
        end

        def to_fit
          csv_records = CSV.read(@file)
          @output_file ||= "#{@file}.fit"

          records = []

          csv_records.each_with_index do |row, index|
            next if index.zero?

            row = CSV.parse(row.join(','), converters: %i[numeric])[0]

            case row[0]
            when 'Definition'
              next
            when 'Data'
              fields = {}
              current_field = ''
              row[3..-1].each_with_index do |cell, i|
                case i % 3
                when 0
                  current_field = cell.to_sym
                  fields[current_field] = {}
                when 1
                  if cell =~ /^\d+\|.+\d+$/
                    cell = cell.split('|').map(&:to_i)
                  end
                  fields[current_field][:value] = cell
                when 2
                  next
                end
              end

              records << {
                local_message_number: row[1].to_i,
                message_name: row[2].to_sym,
                fields: fields
              }
            end

          end

          F4R::encode(@output_file, records, @source_fit_file)
          return 0
        end

        def to_csv
          @records ||= get_records(@file)
          @output_file ||= "#{@file}.csv"

          CSV.open(@output_file, 'wb') do |csv_file|

            largest_message = @records.map {|r| r[:fields].count }.sort.last
            main_header = [
              'type', 'Local Number', 'Message', 'Field 1', 'Value 1', 'Units 1'
            ]

            (largest_message - 1).times do |index|
              main_header += [
                "Field #{index}", "Value #{index}", "Units #{index}"
              ]
            end
            csv_file << main_header

            definitions = []

            @records.each do |record|
              unless definitions.include? record[:message_name]
                definitions << record[:message_name]

                msg = [
                  'Definition',
                  record[:local_message_number],
                  record[:message_name]
                ]

                record[:fields].each do |name, field|
                  msg += [name, field[:properties][:example], nil]
                end

                csv_file << msg
              end

              msg = ['Data', record[:local_message_number], record[:message_name]]

              record[:fields].each do |name, field|
                msg += [name, to_human(field), field[:properties][:units]]
              end

              csv_file << msg
            end
          end

          return 0
        end

        private

        def get_records(source_fit_file)
          records = F4R::decode(source_fit_file).records.inject([]) do |r, record|
            record[:fields].each { |_,f| f[:definition] = f[:definition].snapshot }
            r << record; r
          end

          if @options.ignore_undocumented?
            records = records.
              select { |r| !r[:message_name].to_s.match?(/^undocumented_\d+$/) }.
              map do |r|
              r[:fields] = r[:fields].
                select { |k,v| !k.to_s.match?(/^undocumented_field_\d+$/) }
              r
            end
          end

          if @options.ignore_guessed?
            records = records.
              select { |r| !r[:source].to_s.match?(/^F4R_\d+$/) }.
              map do |r|
              r[:fields] = r[:fields].
                select { |k,v| !v[:properties][:source].match?(/^F4R/) }
              r
            end
          end

          records
        end

      end

    end

  end

end
