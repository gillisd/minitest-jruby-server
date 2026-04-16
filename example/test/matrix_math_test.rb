require "test_helper"
require "matrix_math"

## Tests for Example::MatrixMath operations.
class MatrixMathTest < Minitest::Test
  def setup
    @mm = Example::MatrixMath.new
  end

  def test_multiply_2x2
    a = [[1, 2], [3, 4]]
    b = [[5, 6], [7, 8]]

    assert_equal [[19, 22], [43, 50]], @mm.multiply(a, b)
  end

  def test_multiply_identity
    m = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
    id = @mm.identity(3)

    assert_equal m, @mm.multiply(m, id)
  end

  def test_multiply_20x20
    result = multiply_sequential_matrices(20)

    assert_equal 20, result.length
    assert_equal 20, result[0].length
    expected = (0...20).sum { |k| (k + 1) * (k + 1) }

    assert_equal expected, result[0][0]
  end

  def test_transpose
    m = [[1, 2, 3], [4, 5, 6]]

    assert_equal [[1, 4], [2, 5], [3, 6]], @mm.transpose(m)
  end

  def test_determinant_2x2
    assert_equal(-2, @mm.determinant([[1, 2], [3, 4]]))
  end

  def test_determinant_3x3
    m = [[6, 1, 1], [4, -2, 5], [2, 8, 7]]

    assert_equal(-306, @mm.determinant(m))
  end

  def test_dot_product
    assert_equal 32, @mm.dot_product([1, 2, 3], [4, 5, 6])
  end

  def test_identity
    id = @mm.identity(3)

    assert_equal [[1, 0, 0], [0, 1, 0], [0, 0, 1]], id
  end

  private

  def build_sequential_matrix(size)
    Array.new(size) { |i| Array.new(size) { |j| i + j + 1 } }
  end

  def build_product_matrix(size)
    Array.new(size) { |i| Array.new(size) { |j| (i + 1) * (j + 1) } }
  end

  def multiply_sequential_matrices(size)
    @mm.multiply(build_sequential_matrix(size), build_product_matrix(size))
  end
end
