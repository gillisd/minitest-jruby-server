require "test_helper"
require "calculator"

## Tests for Example::Calculator arithmetic operations.
class CalculatorTest < Minitest::Test
  def setup
    @calc = Example::Calculator.new
  end

  def test_add
    assert_equal 7, @calc.add(3, 4)
  end

  def test_subtract
    assert_equal 1, @calc.subtract(4, 3)
  end

  def test_multiply
    assert_equal 12, @calc.multiply(3, 4)
  end

  def test_divide
    assert_in_delta 2.5, @calc.divide(5, 2)
  end

  def test_factorial
    assert_equal 120, @calc.factorial(5)
  end
end
