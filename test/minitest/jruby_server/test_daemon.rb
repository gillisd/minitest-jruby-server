require "test_helper"

class TestDaemon < Minitest::Test
  FakeRunner = Struct.new(:call_count) do
    def initialize
      super(0)
    end

    def run(seed: nil, include_filter: nil, exclude_filter: nil)
      self.call_count += 1
      { seed: seed || 42, tests: 5, assertions: 10, failures: 0,
        errors: 0, skips: 0, passed: true, time: 0.001, output: "" }
    end
  end

  def setup
    @fake_runner = FakeRunner.new
    @daemon = Minitest::JRubyServer::Daemon.new(runner: @fake_runner)
  end

  def test_run_tests_delegates_to_runner
    @daemon.run_tests(seed: 99)
    assert_equal 1, @fake_runner.call_count
  end

  def test_run_tests_adds_run_number
    result = @daemon.run_tests(seed: 99)
    assert_equal 1, result[:run]
  end

  def test_run_tests_adds_engine
    result = @daemon.run_tests
    assert_kind_of String, result[:engine]
    assert_match(/ruby|jruby/, result[:engine])
  end

  def test_run_count_increments
    3.times { @daemon.run_tests }
    assert_equal 3, @fake_runner.call_count
    result = @daemon.run_tests
    assert_equal 4, result[:run]
  end

  def test_info_returns_required_keys
    info = @daemon.info
    %i[engine pid runs_so_far uptime].each do |key|
      assert info.key?(key), "Expected info to have key :#{key}"
    end
  end

  def test_info_tracks_run_count
    2.times { @daemon.run_tests }
    assert_equal 2, @daemon.info[:runs_so_far]
  end

  def test_ping
    assert_equal :pong, @daemon.ping
  end
end
