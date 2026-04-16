module Example
  class MatrixMath
    def multiply(a, b)
      rows_a = a.length
      cols_b = b[0].length
      cols_a = a[0].length

      result = Array.new(rows_a) { Array.new(cols_b, 0) }

      rows_a.times do |i|
        cols_b.times do |j|
          sum = 0
          cols_a.times do |k|
            sum += a[i][k] * b[k][j]
          end
          result[i][j] = sum
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
      n = matrix.length
      return matrix[0][0] if n == 1
      return (matrix[0][0] * matrix[1][1]) - (matrix[0][1] * matrix[1][0]) if n == 2

      det = 0
      n.times do |j|
        sub = submatrix(matrix, 0, j)
        sign = j.even? ? 1 : -1
        det += sign * matrix[0][j] * determinant(sub)
      end
      det
    end

    def dot_product(v1, v2)
      sum = 0
      v1.length.times { |i| sum += v1[i] * v2[i] }
      sum
    end

    def identity(n)
      Array.new(n) { |i| Array.new(n) { |j| i == j ? 1 : 0 } }
    end

    private

    def submatrix(matrix, row, col)
      matrix.each_with_index.filter_map { |r, i|
        next if i == row

        r.each_with_index.filter_map { |v, j| v unless j == col }
      }
    end
  end
end
