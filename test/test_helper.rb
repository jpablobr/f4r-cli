$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'f4r/cli'
require 'minitest/autorun'

ENV['TZ'] = 'UTC'

F4R::Log.level = 8
F4R::Log.color = false

TEST_ROOT = File.dirname(__FILE__)

def fit_csv_tool_check(file)
  require 'open3'

  _, stdout, stderr, wait_thr = Open3.popen3(
    'java',
    '-jar',
    File.join(TEST_ROOT, 'FitCSVTool.jar'),
    '-i',
    file
  )

  stdout.gets(nil)
  stdout.close
  stderr.gets(nil)
  stderr.close

  wait_thr.value.exitstatus
end

def test_file(filename)
  File.join(TEST_ROOT, 'fixtures', filename)
end
