require 'test_helper'

describe F4R::CLI::Activity do

  let(:tmp_file) { 'tmp_file' }

  describe '--to-csv' do

    it 'creates editable CSV file specific to swim activity' do
      args = [
        'to-csv',
        test_file('swim-activity.fit'),
        "--output-file=#{tmp_file}"
      ]

      _(F4R::CLI::Activity.start(args)).must_equal 0
    end

  end

  describe '--to-fit' do

    let(:source_fit_file) { test_file('swim-activity.fit') }

    it 'Edits source FIT file' do
      # Read source first for comparison.
      a = F4R.decode(source_fit_file)

      _(a.records.count).must_equal 168

      length_strokes = a.records.select { |r| r[:message_name] == :length }.
        map { |r| r[:fields][:swim_stroke][:value] }
      _(length_strokes).must_equal [0, 0, 0, 255, 4, 4, 4, 4, 255]

      length_indexes = a.records.select { |r| r[:message_name] == :length }.
        map { |r| r[:fields][:message_index][:value] }
      _(length_indexes).must_equal [0, 1, 2, 3, 4, 5, 6, 7, 8]

      lap_strokes = a.records.select { |r| r[:message_name] == :lap }.
        map { |r| r[:fields][:swim_stroke][:value] }
      _(lap_strokes).must_equal [0, 255, 4, 255]

      args = [
        'to-fit',
        test_file('swim-activity-edited.csv'),
        "--source-fit-file=#{source_fit_file}",
        "--output-file=#{tmp_file}"
      ]

      _(F4R::CLI::Activity.start(args)).must_equal 0
      _(fit_csv_tool_check(tmp_file)).must_equal 0

      # Read edited file
      b = F4R.decode(tmp_file)
      _(b.records.count).must_equal 168

      length_strokes = b.records.select { |r| r[:message_name] == :length }.
        map { |r| r[:fields][:swim_stroke][:value] }
      _(length_strokes).must_equal [0, 0, 0, 0, 255, 4, 4, 4, 255]

      length_indexes = b.records.select { |r| r[:message_name] == :length }.
        map { |r| r[:fields][:message_index][:value] }
      _(length_indexes).must_equal [0, 1, 2, 3, 4, 5, 6, 7, 8]

      lap_strokes = b.records.select { |r| r[:message_name] == :lap }.
        map { |r| r[:fields][:swim_stroke][:value] }
      _(lap_strokes).must_equal [0, 255, 4, 255]

      a_kv = a.records.select {|r| r[:message_name] == :lap }.map do |r|
        r[:fields].map {|k,v| [k, v[:value]] }
      end

      b_kv = b.records.select {|r| r[:message_name] == :lap }.map do |r|
        r[:fields].map {|k,v| [k, v[:value]] }
      end

      a_kv.each_with_index do |r, index|
        r.to_h.each do |k,v|
          _(b_kv[index].to_h[k]).must_equal v
        end
      end
    end

  end

  before { File.delete(tmp_file) if File.exist?(tmp_file) }
  after { File.delete(tmp_file) if File.exist?(tmp_file) }

end
