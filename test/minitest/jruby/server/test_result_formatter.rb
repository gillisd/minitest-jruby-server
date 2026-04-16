require "test_helper"
require "stringio"

class TestResultFormatter < Minitest::Test
  def setup
    @io  = StringIO.new
    @fmt = Minitest::JRuby::Server::ResultFormatter.new(io: @io)
  end

  def test_print_run_result_shows_status
    result = { run: 1, seed: 42, tests: 5, assertions: 10,
               failures: 0, errors: 0, skips: 0, passed: true, time: 0.123,
               engine: "jruby 10.0.4.0" }
    @fmt.print_run_result(result)

    assert_match(/PASS/, @io.string)
    assert_match(/5 tests/, @io.string)
  end

  def test_print_run_result_shows_fail
    result = { run: 1, seed: 42, tests: 5, assertions: 10,
               failures: 2, errors: 0, skips: 0, passed: false, time: 0.123,
               engine: "jruby 10.0.4.0" }
    @fmt.print_run_result(result)

    assert_match(/FAIL/, @io.string)
  end

  def test_print_server_info
    info = { engine: "jruby 10.0.4.0", pid: 12_345, runs_so_far: 3, uptime: 60.5 }
    @fmt.print_server_info(info)

    assert_match(/jruby/, @io.string)
    assert_match(/12345/, @io.string)
  end

  def test_print_summary_with_warmup_trend
    times = [1.0, 0.5, 0.2, 0.1, 0.05, 0.04]
    @fmt.print_summary(times: times)
    output = @io.string

    assert_match(/Fastest/, output)
    assert_match(/Slowest/, output)
  end
end
