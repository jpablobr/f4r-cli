require 'csv'
require 'hashie'

module F4R

  module CLI

    module Sport

      class LapSwim

        include F4R::CLI::Converters

        class FITRecord < Hashie::Dash

          extend F4R::CLI::Converters
          include Hashie::Extensions::Dash::PropertyTranslation
          include Hashie::Extensions::Dash::Coercion

          def self.set_properties
            record_name = self.name.gsub(/.+::/, '').downcase.to_sym

            F4R::GlobalFit.messages.
              find { |m| m[:name] == record_name }[:fields].
              map { |f| f[:field_name] }.each do |field|
              property field, transform_with: ->(value) { to_human(value) }
            end
          end

        end

        class Session < FITRecord
          set_properties
        end

        class Length < FITRecord

          include F4R::CLI::Converters

          set_properties

          property :pool_length

          def rest?
            length_type == 'idle' || total_strokes.nil?
          end

          def labels(index, lap)
            @labels ||= {
              interval: 'Length',
              message_index: message_index,
              num_lengths: '', # lap only
              num_active_lengths: '', # lap only
              length_type: length_type,
              swim_stroke: swim_stroke,
              distance: pool_length * (message_index+1),
              timestamp: timestamp,
              start_time: start_time,
              total_elapsed_time: total_elapsed_time,
              total_timer_time: total_timer_time,
              cumulative_time: cumulative_time(self, lap),
              total_distance: '', # only lap
              total_strokes: total_strokes,
              total_calories: total_calories,
              avg_speed: avg_speed,
              max_speed: '', # lap only
              avg_stroke_distance: '', # lap only
              avg_cadence: '', # lap only
              avg_temperature: '', # lap only
              max_temperature: '', # lap only
              min_temperature: '', # lap only
              avg_pace: avg_pace(total_timer_time, rest?),
              avg_swolf: length_avg_swolf(self, rest?),
            }
          end

        end

        class Lap < FITRecord

          include F4R::CLI::Converters

          set_properties

          property :pool_length
          property :lengths, coerce: Array[Length]

          def labels
            @labels ||= {
              interval: 'Interval',
              message_index: message_index,
              num_lengths: num_lengths,
              num_active_lengths: num_active_lengths,
              length_type: '',
              swim_stroke: swim_stroke,
              distance: active_lengths_count(self) * pool_length,
              timestamp: timestamp,
              start_time: start_time,
              total_elapsed_time: total_elapsed_time,
              total_timer_time: total_timer_time,
              cumulative_time: ("%02d:%02d" % total_elapsed_time.divmod(60)),
              total_distance: total_distance,
              total_strokes: total_cycles,
              total_calories: total_calories,
              avg_speed: avg_speed,
              max_speed: max_speed,
              avg_stroke_distance: avg_stroke_distance,
              avg_cadence: avg_cadence,
              avg_temperature: avg_temperature,
              max_temperature: max_temperature,
              min_temperature: min_temperature,
              avg_pace: avg_pace(lap_total_active_time(self), false, total_distance),
              avg_swolf: lap_avg_swolf(self),
            }
          end

        end

        class Activity < FITRecord

          set_properties

          property :laps, coerce: Array[Lap]
          property :session, coerce: Session

        end

        attr_reader :activity

        def initialize(records, options)
          @records = records
          @output_file = options.output_file || "#{@file}.csv"
          @activity ||= get_activity
          @source_fit_file = options.source_fit_file

          session = @records.find { |r| r[:message_name] == :session }
          activity.session = Session.new(session[:fields])

          build_laps
        end

        def to_fit(csv_file)
          csv_records = CSV.read(csv_file)
          @output_file ||= "#{csv_file}.fit"

          laps = []
          current_lap = nil
          csv_records.each_with_index do |row, index|
            next if index.zero?

            row = CSV.parse(row.join(','), converters: %i[numeric])[0]
            if row[0] =~ /^Interval$/
              current_lap = row[1]
              laps << {
                message_index: row[1],
                num_lengths: row[2],
                num_active_lengths: row[3],
                swim_stroke: row[5],
                timestamp: row[7],
                start_time: row[8],
                total_elapsed_time: row[9],
                total_timer_time: row[10],
                total_distance: row[12],
                total_strokes: row[13],
                total_calories: row[14],
                avg_speed: row[15],
                max_speed: row[16],
                avg_stroke_distance: row[17],
                avg_cadence: row[18],
                avg_temperature: row[19],
                max_temperature: row[20],
                min_temperature: row[21],
                lengths: []
              }
            else
              laps[current_lap][:lengths] << {
                message_index: row[1],
                length_type: row[4],
                swim_stroke: row[5],
                timestamp: row[7],
                start_time: row[8],
                total_elapsed_time: row[9],
                total_timer_time: row[10],
                total_strokes: row[13],
                total_calories: row[14],
              }
            end
          end

          laps.each_with_index do |lap, index|
            source_lap = @records.find do |l|
              l[:message_name] == :lap &&
                l[:fields][:message_index][:value] == lap[:message_index]
            end

            if source_lap
              lap.each do |name, value|
                next if name == :lengths
                field = source_lap[:fields][name]
                if field
                  value = human_to_fit(value, field[:properties])
                  @records[source_lap[:index]][:fields][name][:value] = value
                end
              end
            else
              raise 'Source Lap not found. Adding or deleting not supported.'
            end

            # Add lengths
            if lap[:lengths].count > activity.laps[index].lengths.count
              new_length_count = lap[:lengths].count - activity.laps[index].lengths.count
              length_deep_copy = length_deep_copy(index)

              new_length_count.times do |time|
                @records.insert(length_deep_copy[:index], length_deep_copy)
                activity.laps[index].lengths << Length.new(length_deep_copy[:fields])
              end

              update_indexes!(length_deep_copy)
            end

            # Remove lengths
            if lap[:lengths].count < activity.laps[index].lengths.count
              a = lap[:lengths].map { |l| l[:message_index] }
              b = activity.laps[index].lengths.map { |l| l[:message_index] }
              diff = b - a

              diff.each do |diff_index|
                r_index = @records.find do |r|
                  r[:message_name] == :length &&
                    r[:fields][:message_index][:value] == diff_index
                end[:index]

                @records.delete_at(r_index)

                a_index = activity.laps[index].lengths.
                  find_index { |l| l.message_index == diff_index }
                activity.laps[index].lengths.delete_at(a_index)
              end

              update_indexes!(length_deep_copy(index))
            end

            # Update all lengths
            lap[:lengths].each do |length|
              source_length = @records.find do |l|
                l[:message_name] == :length &&
                  l[:fields][:message_index][:value] == length[:message_index]
              end

              if source_length
                length.each do |name, value|
                  field = source_length[:fields][name]
                  if field
                    value = human_to_fit(value, field[:properties])
                    @records[source_length[:index]][:fields][name][:value] = value
                  end
                end
              end
            end
          end

          F4R::encode(@output_file, @records, @source_fit_file)
          return 0
        end

        def to_csv
          CSV.open(@output_file, 'wb') do |csv_file|

            csv_file << [
              'Type*',
              'Index',
              'Lengths*',
              'Active Lengths*',
              'Length Type*',
              'Stroke',
              'Distance*',
              'Timestamp',
              'Start Time',
              'Total Elapsed Time',
              'Total Timer Time',
              'Cumulative Time*',
              'Total Distance*',
              'Total Strokes*',
              'Total Calories*',
              'Avg Speed',
              'Max Speed',
              'Avg Stroke Distance',
              'Avg Cadence',
              'Avg Temp',
              'Max Temp',
              'Min Temp',
              'Avg Pace*',
              'Avg Swolf*',
            ]

            activity.laps.each do |lap|
              csv_file << lap.labels.map { |_,v| v }
              lap.lengths.each_with_index do |l, index|
                csv_file << l.labels(index, lap).map{ |_,v| v }
              end
            end
          end

          return 0
        end

        private

        def get_activity
          a = @records.find { |r| r[:message_name] == :activity }
          Activity.new(a[:fields].merge(laps: []))
        end

        def build_laps
          pool_length = {pool_length: activity.session.pool_length}
          source_lengths = @records.select { |r| r[:message_name] == :length }

          @records.select { |r| r[:message_name] == :lap }.each do |lap|
            dash_lap = Lap.new(lap[:fields].merge({lengths: []}))
            dash_lap.pool_length = activity.session.pool_length

            if lap[:fields][:num_lengths][:value].zero?
              length = source_lengths.shift
              dash_lap.lengths << Length.new(length[:fields].merge(pool_length))
            else
              lap[:fields][:num_lengths][:value].times do |index|
                length = source_lengths.shift
                dash_lap.lengths << Length.new(length[:fields].merge(pool_length))
              end
            end

            activity.laps << dash_lap
          end
        end

        def length_deep_copy(index)
          length_deep_copy = @records.find do |r|
            lap_length_index = activity.laps[index].lengths.last.message_index
            r[:message_name] == :length &&
              r[:fields][:message_index][:value] == lap_length_index
          end

          Marshal.load(Marshal.dump(length_deep_copy))
        end

        def update_indexes!(length_deep_copy)
          index_count = 0
          activity.laps.each do |l|
            l.lengths.each do |le|
              field = length_deep_copy[:fields][:message_index]
              field = Marshal.load(Marshal.dump(field))
              field[:value] = index_count
              le.message_index = field
              index_count += 1
            end
          end

          @records.each_with_index { |r,i| r[:index] = i }

          @records.select { |r| r[:message_name] == :length }.each_with_index do |r,i|
            r[:fields][:message_index][:value] = i
          end
        end

      end

    end

  end

end
