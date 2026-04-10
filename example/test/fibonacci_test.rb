require "test_helper"
require "fibonacci"

class FibonacciTest < Minitest::Test
  def setup
    @fib = Example::Fibonacci.new
  end

  def test_base_cases
    assert_equal 0, @fib.compute(0)
    assert_equal 1, @fib.compute(1)
  end

  def test_small_values
    assert_equal 5, @fib.compute(5)
    assert_equal 8, @fib.compute(6)
  end

  def test_larger_value
    assert_equal 6765, @fib.compute(20)
  end

  def test_sequence
    assert_equal [0, 1, 1, 2, 3, 5, 8], @fib.sequence(7)
  end
end
