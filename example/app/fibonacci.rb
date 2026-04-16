module Example
  ## Computes Fibonacci numbers iteratively.
  class Fibonacci
    def compute(count)
      return count if count <= 1

      a = 0
      b = 1
      (count - 1).times { a, b = b, a + b }
      b
    end

    def sequence(count)
      (0...count).map { |i| compute(i) }
    end
  end
end
