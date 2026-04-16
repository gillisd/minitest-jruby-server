module Example
  class Fibonacci
    def compute(n)
      return n if n <= 1

      a = 0
      b = 1
      (n - 1).times { a, b = b, a + b }
      b
    end

    def sequence(n)
      (0...n).map { |i| compute(i) }
    end
  end
end
