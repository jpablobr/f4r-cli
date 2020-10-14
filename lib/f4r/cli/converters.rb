require 'time'

module F4R

  module CLI

    module Converters

      def to_human(field)
        if field[:value].is_a? Array
          if field[:value] == [field[:base_type][:undef]]*field[:value].size
            value = nil
          else
            value = field[:value].map { |v| value_to_human(v, field[:properties]) }
          end
        else
          if field[:value] == field[:base_type][:undef]
            value = nil
          else
            type = F4R::GlobalFit.types[field[:properties][:field_type]]
            if type
              field_type = type[:values].find {|gt| gt[:value] == field[:value] }
              if field_type
                value = field_type[:value_name]
              else
                value = value_to_human(field[:value], field[:properties])
              end
            else
              value = value_to_human(field[:value], field[:properties])
            end
          end
        end

        value = value.join('|') if value.is_a? Array
        value
      end

      def value_to_human(value, properties)
        value /= properties[:scale].to_f if properties[:scale]
        value -= properties[:offset] if properties[:offset]

        case properties[:field_type]
        when 'coordinate'
          value *= 180.0 / 2147483648
        when 'date_time'
          value = fit_time_to_time(value).strftime("%Y-%m-%d %H:%M:%S")
        # when 'duration'
        #   value = secsToDHMS(value)
        end

        if properties[:field_type] == :string
          value = value.unpack('A*')[0]
        end

        value
      end

      def human_to_fit(value, properties)
        type = F4R::GlobalFit.types[properties[:field_type]]
        if type
          value = value.downcase.to_sym if value.is_a? String
          field_type = type[:values].find {|gt| gt[:value_name] == value }
          if field_type
            value = field_type[:value]
          else
            value = value_to_fit(value, properties)
          end
        else
          value = value_to_fit(value, properties)
        end
        value
      end

      def value_to_fit(value, properties)
        return nil if value.nil?

        value *= properties[:scale].to_f if properties[:scale]
        value += properties[:offset] if properties[:offset]

        case properties[:field_type]
        when 'coordinate'
          value /= 180.0 * 2147483648
        when 'date_time'
          value = time_to_fit_time(value).strftime("%Y-%m-%d %H:%M:%S")
        # when 'duration'
        #   value = secsToDHMS(value)
        end

        value.to_i unless value.is_a?(String) || value.is_a?(Symbol)
      end

      def conversion_factor(from_unit, to_unit)
        factors = {
          'm' => { 'km' => 0.001, 'in' => 39.3701, 'ft' => 3.28084,
            'mi' => 0.000621371 },
          'mm' => { 'cm' => 0.1, 'in' => 0.0393701 },
          'm/s' => { 'km/h' => 3.6, 'mph' => 2.23694 },
          'min/km' => { 'min/mi' => 1.60934 },
          'kg' => { 'lbs' => 0.453592 }
        }
        return 1.0 if from_unit == to_unit
        unless factors.include?(from_unit)
          Log.fatal "No conversion factors defined for unit " +
            "'#{from_unit}' to '#{to_unit}'"
        end

        factor = factors[from_unit][to_unit]
        if factor.nil?
          Log.fatal "No conversion factor from '#{from_unit}' to '#{to_unit}' " +
            "defined."
        end
        factor
      end

      def speedToPace(speed, distance = 1000.0)
        if speed && speed > 0.01
          # We only show 2 fractional digits, so make sure we round accordingly
          # before we crack it up.
          pace = (distance.to_f / (speed * 60.0)).round(2)
          int, dec = pace.divmod 1
          "#{int}:#{'%02d' % (dec * 60)}"
        else
          "-:--"
        end
      end

      def secsToHM(secs)
        secs = secs.to_i
        s = secs % 60
        mins = secs / 60
        m = mins % 60
        h = mins / 60
        "#{h}:#{'%02d' % m}"
      end

      def secsToHMS(secs)
        secs = secs.to_i
        s = secs % 60
        mins = secs / 60
        m = mins % 60
        h = mins / 60
        "#{h}:#{'%02d' % m}:#{'%02d' % s}"
      end

      def secsToDHMS(secs)
        secs = secs.to_i
        s = secs % 60
        mins = secs / 60
        m = mins % 60
        hours = mins / 60
        h = hours % 24
        d = hours / 24
        "#{d} days #{h}:#{'%02d' % m}:#{'%02d' % s}"
      end

      def time_to_fit_time(t)
        (t - Time.parse('1989-12-31T00:00:00+00:00')).to_i
      end

      def fit_time_to_time(ft)
        Time.parse('1989-12-31T00:00:00+00:00') + ft.to_i
      end

      # e.g., 0:59/100mts
      def avg_pace speed, rest, distance=50.00
        if speed > 0 and distance > 0 and !rest
          pace = (speed.to_f * 100) / distance.to_f
          int, dec = pace.divmod(60)
          "#{int}:#{'%02d' % (dec)}"
        else
          '' # '-:--'
        end
      end

      def lap_avg_strokes lap
        lengths = active_lengths_count(lap)
        if lengths > 0
          '%02d' % (lap_total_strokes(lap) / lengths)
        else
          '' # '--'
        end
      end

      def lap_total_active_time lap
        lap.lengths.map do |l|
          l.total_timer_time unless l.total_strokes.nil?
        end.sum(&:to_f)
      end

      def lap_total_strokes lap
        lap.lengths.map {|l| l.total_strokes.to_i}.sum
      end

      def active_lengths_count lap
        lap.lengths.count {|l| !l.total_strokes.nil?}
      end

      # https://support.garmin.com/en-AU/?faq=8ms6votkT31TRIBfCVs9WA
      def lap_avg_swolf lap
        total_strokes = lap_total_strokes(lap)
        active_time = lap_total_active_time(lap)

        if total_strokes > 0
          ('%02d' % ((active_time + total_strokes) / active_lengths_count(lap)))
        else
          '' # '--'
        end
      end

      def length_avg_swolf length, rest
        swolf = length.total_timer_time.to_i + length.total_strokes.to_i

        if rest || length.total_strokes == 0
          '' # '--'
        else
          swolf.to_i
        end
      end

      def cumulative_time length, lap
        if length.total_strokes.nil?
          '' # '-:--'
        else
          time = ((length.start_time.to_f + length.total_timer_time) - lap.start_time.to_f)
          '%02d:%02d' % time.divmod(60)
        end
      end

    end

  end

end
