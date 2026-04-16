require "test_helper"

# Define test classes that Runner will execute
class RunnerDemoTest < Minitest::Test
  def test_passing
    assert true
  end

  def test_also_passing
    assert_equal 4, 2 + 2
  end
end

class TestRunner < Minitest::Test
  def setup
    @runner = Minitest::Jruby::Server::Runner.new
  end

  def test_run_returns_hash_with_required_keys
    result = run_runner(seed: 42)

    %i[seed tests assertions failures errors skips passed time output].each do |key|
      assert result.key?(key), "Expected result to have key :#{key}"
    end
  end

  def test_run_executes_tests
    result = run_runner(seed: 42)

    assert_operator result[:tests], :>=, 2
    assert_operator result[:assertions], :>=, 2
  end

  def test_run_with_default_seed
    result = run_runner

    assert_kind_of Integer, result[:seed]
  end

  def test_run_with_include_filter
    result = run_runner(seed: 42, include_filter: "/RunnerDemoTest/")

    assert result[:passed]
    assert_operator result[:tests], :>=, 2
  end

  def test_run_with_exclude_filter
    result = run_runner(seed: 42, exclude_filter: "/RunnerDemoTest/")
    result2 = run_runner(seed: 42)

    assert_operator result[:tests], :<, result2[:tests]
  end

  def test_run_reports_time
    result = run_runner(seed: 42)

    assert_kind_of Float, result[:time]
    assert_operator result[:time], :>=, 0
  end

  def test_run_captures_output
    result = run_runner(seed: 42)

    assert_kind_of String, result[:output]
    assert_match(/\d+ runs/, result[:output])
  end

  def test_run_with_invalid_filter_raises
    assert_raises Minitest::Jruby::Server::InvalidFilter do
      @runner.run(seed: 42, include_filter: "/[invalid/")
    end
  end

  def test_successive_runs_are_independent
    r1 = run_runner(seed: 100)
    r2 = run_runner(seed: 200)

    assert r1[:passed]
    assert r2[:passed]
    refute_equal r1[:seed], r2[:seed]
  end

  private

  def run_runner(**kwargs)
    saved = Minitest::Runnable.runnables.dup
    # Keep only RunnerDemoTest other test classes from parallel test files
    # may have DRb dependencies or side effects that fail in this context
    Minitest::Runnable.runnables.replace([RunnerDemoTest])
    @runner.run(**kwargs)
  ensure
    Minitest::Runnable.runnables.replace(saved)
  end
end
