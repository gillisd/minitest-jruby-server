module Example
  class Calculator
    def add(a, b) = a + b
    def subtract(a, b) = a - b
    def multiply(a, b) = a * b
    def divide(a, b) = a.to_f / b
    def power(a, b) = a**b
    def factorial(n) = (1..n).reduce(1, :*)
  end
end
