require "test_helper"
require "tmpdir"
require "fileutils"

class TestTestLoader < Minitest::Test
  def setup
    @dir = Dir.mktmpdir("minitest-loader-test")
    FileUtils.mkdir_p(File.join(@dir, "test"))
    FileUtils.mkdir_p(File.join(@dir, "lib"))

    File.write File.join(@dir, "lib", "widget.rb"), <<~RUBY
      class Widget; end
    RUBY

    File.write File.join(@dir, "test", "widget_test.rb"), <<~RUBY
      require "minitest/test"
      require "widget"
      class WidgetTest < Minitest::Test
        def test_exists
          assert Widget
        end
      end
    RUBY
  end

  def teardown
    FileUtils.rm_rf(@dir)
  end

  def test_discovers_test_files
    config = Minitest::JRubyServer::Config.new(project_root: @dir)
    loader = Minitest::JRubyServer::TestLoader.new(config: config)
    assert_includes loader.test_files.map { |f| File.basename(f) }, "widget_test.rb"
  end

  def test_raises_when_no_tests_found
    empty_dir = Dir.mktmpdir("minitest-empty")
    FileUtils.mkdir_p(File.join(empty_dir, "test"))
    config = Minitest::JRubyServer::Config.new(project_root: empty_dir)
    loader = Minitest::JRubyServer::TestLoader.new(config: config)

    assert_raises Minitest::JRubyServer::NoTestsFound do
      loader.load_tests!
    end
  ensure
    FileUtils.rm_rf(empty_dir)
  end
end
