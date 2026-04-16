module Example
  ## Matrix and vector arithmetic operations.
  class MatrixMath
    def multiply(left, right)
      rows = left.length
      cols = right[0].length
      inner = left[0].length

      result = Array.new(rows) { Array.new(cols, 0) }

      rows.times do |i|
        cols.times do |j|
          result[i][j] = dot_row_col(left, right, i, j, inner)
        end
      end

      result
    end

    def transpose(matrix)
      rows = matrix.length
      cols = matrix[0].length
      Array.new(cols) { |j| Array.new(rows) { |i| matrix[i][j] } }
    end

    def determinant(matrix)
      return matrix[0][0] if matrix.length == 1
      return (matrix[0][0] * matrix[1][1]) - (matrix[0][1] * matrix[1][0]) if matrix.length == 2

      cofactor_expansion(matrix)
    end

    def dot_product(v1, v2)
      sum = 0
      v1.length.times { |i| sum += v1[i] * v2[i] }
      sum
    end

    def identity(size)
      Array.new(size) { |i| Array.new(size) { |j| i == j ? 1 : 0 } }
    end

    private

    def dot_row_col(left, right, row, col, inner)
      sum = 0
      inner.times { |k| sum += left[row][k] * right[k][col] }
      sum
    end

    def cofactor_expansion(matrix)
      det = 0
      matrix.length.times do |j|
        sub = submatrix(matrix, 0, j)
        sign = j.even? ? 1 : -1
        det += sign * matrix[0][j] * determinant(sub)
      end
      det
    end

    def submatrix(matrix, row, col)
      matrix.each_with_index.filter_map { |r, i|
        next if i == row

        r.each_with_index.filter_map { |v, j| v unless j == col }
      }
    end
  end
end
