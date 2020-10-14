require 'test_helper'
require 'csv'

describe F4R::CLI::Export do
  let(:tmp_file) { 'tmp_file' }

  describe '--to-csv' do

    it 'creates CSV file' do
      args = [
        'to-csv',
        test_file('4167256290.fit'),
        "--output-file=#{tmp_file}"
      ]

      _(F4R::CLI::Export.start(args)).must_equal 0

      csv = CSV.read(tmp_file)

      _(csv.count).must_equal 53
      _(csv[0].count).must_equal 288

      _(csv[1]).must_equal [
        'Definition', '0', 'file_id',
        'serial_number', '1', nil,
        'time_created', '1', nil,
        'undocumented_field_7', nil, nil,
        'manufacturer', '1', nil,
        'product', '1', nil,
        'number', '1', nil,
        'type', '1', nil]

      _(csv[2]).must_equal [
        'Data', '0', 'file_id',
        'serial_number', '3980689448', nil,
        'time_created', '940290974', nil,
        'undocumented_field_7', nil, nil,
        'manufacturer', 'garmin', nil,
        'product', '3126', nil,
        'number', nil, nil,
        'type', 'activity', nil]

      _(csv.find { |record| record[2] == 'battery' }).must_equal [
        'Definition', '0', 'battery',
        'timestamp', nil, nil,
        'unit_voltage', nil, nil,
        'undocumented_field_1', nil, nil,
        'percent', nil, nil,
        'current', nil, nil]

      _(csv.find { |record| record[2] == 'undocumented_125' }).must_equal [
        'Definition', '1', 'undocumented_125',
        'timestamp', nil, nil,
        'undocumented_field_2', nil, nil,
        'undocumented_field_3', nil, nil,
        'undocumented_field_1', nil, nil,
        'undocumented_field_4', nil, nil]
    end

    it '--ignore-undocumented' do
      args = [
        'to-csv',
        test_file('4167256290.fit'),
        '--ignore_undocumented',
        "--output-file=#{tmp_file}"
      ]

      _(F4R::CLI::Export.start(args)).must_equal 0

      csv = CSV.read(tmp_file)

      _(csv.count).must_equal 49
      _(csv[0].count).must_equal 234

      _(csv[1]).must_equal [
        'Definition', '0', 'file_id',
        'serial_number', '1', nil,
        'time_created', '1', nil,
        'manufacturer', '1', nil,
        'product', '1', nil,
        'number', '1', nil,
        'type', '1', nil]

      _(csv[2]).must_equal [
        'Data', '0', 'file_id',
        'serial_number', '3980689448', nil,
        'time_created', '940290974', nil,
        'manufacturer', 'garmin', nil,
        'product', '3126', nil,
        'number', nil, nil,
        'type', 'activity', nil]

      _(csv.find { |record| record[2] == 'battery' }).must_equal [
        'Definition', '0', 'battery',
        'timestamp', nil, nil,
        'unit_voltage', nil, nil,
        'percent', nil, nil,
        'current', nil, nil]

      assert_nil(csv.find { |record| record[2] == 'undocumented_125' })
    end

    it '--ignore-guessed' do
      args = [
        'to-csv',
        test_file('4167256290.fit'),
        '--ignore-guessed',
        "--output-file=#{tmp_file}"
      ]

      _(F4R::CLI::Export.start(args)).must_equal 0

      csv = CSV.read(tmp_file)

      _(csv.count).must_equal 53
      _(csv[0].count).must_equal 225

      _(csv[1]).must_equal [
        'Definition', '0', 'file_id',
        'serial_number', '1', nil,
        'time_created', '1', nil,
        'manufacturer', '1', nil,
        'product', '1', nil,
        'number', '1', nil,
        'type', '1', nil]

      _(csv[2]).must_equal [
        'Data', '0', 'file_id',
        'serial_number', '3980689448', nil,
        'time_created', '940290974', nil,
        'manufacturer', 'garmin', nil,
        'product', '3126', nil,
        'number', nil, nil,
        'type', 'activity', nil]

      _(csv.find { |record| record[2] == 'battery' }).must_equal [
        'Definition', '0', 'battery']

      _(csv.find { |record| record[2] == 'undocumented_125' }).must_equal [
        'Definition', '1', 'undocumented_125']
    end

    it '--ignore-guessed --ignore-undocumented' do
      args = [
        'to-csv',
        test_file('4167256290.fit'),
        '--ignore-guessed',
        '--ignore-undocumented',
        "--output-file=#{tmp_file}"
      ]

      _(F4R::CLI::Export.start(args)).must_equal 0

      csv = CSV.read(tmp_file)

      _(csv.count).must_equal 49
      _(csv[0].count).must_equal 225

      _(csv[1]).must_equal [
        'Definition', '0', 'file_id',
        'serial_number', '1', nil,
        'time_created', '1', nil,
        'manufacturer', '1', nil,
        'product', '1', nil,
        'number', '1', nil,
        'type', '1', nil]

      _(csv[2]).must_equal [
        'Data', '0', 'file_id',
        'serial_number', '3980689448', nil,
        'time_created', '940290974', nil,
        'manufacturer', 'garmin', nil,
        'product', '3126', nil,
        'number', nil, nil,
        'type', 'activity', nil]

      _(csv.find { |record| record[2] == 'battery' }).must_equal [
        'Definition', '0', 'battery']

      assert_nil(csv.find { |record| record[2] == 'undocumented_125' })
    end
  end

  describe '--to-fit' do

    it 'creates FIT file' do
      args = [
        'to-fit',
        test_file('4167256290.csv'),
        "--output-file=#{tmp_file}"
      ]

      _(F4R::CLI::Export.start(args)).must_equal 0
      _(fit_csv_tool_check(tmp_file)).must_equal 0

      a = F4R.decode(tmp_file)
      _(a.records.count).must_equal 31

      edits = a.records.
        select {|r| r[:message_name] == :record }.
        map {|r| r[:fields][:heart_rate][:value]}
      _(edits).must_equal [255]*3

      # Edit with --source-fit-file
      args = [
        'to-fit',
        test_file('4167256290-edited.csv'),
        "--source-fit-file=#{test_file('4167256290.fit')}",
        "--output-file=#{tmp_file}"
      ]

      _(F4R::CLI::Export.start(args)).must_equal 0
      _(fit_csv_tool_check(tmp_file)).must_equal 0

      a = F4R.decode(tmp_file)
      _(a.records.count).must_equal 31

      edits = a.records.
        select {|r| r[:message_name] == :record }.
        map {|r| r[:fields][:heart_rate][:value]}
      _(edits).must_equal [120]*3
    end

  end

  before { File.delete(tmp_file) if File.exist?(tmp_file) }
  after { File.delete(tmp_file) if File.exist?(tmp_file) }

end
