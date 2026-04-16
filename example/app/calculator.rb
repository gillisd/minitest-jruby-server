module Example
  ## Basic arithmetic operations on numeric values.
  class Calculator
    def add(left, right) = left + right
    def subtract(left, right) = left - right
    def multiply(left, right) = left * right
    def divide(left, right) = left.to_f / right
    def power(left, right) = left**right
    def factorial(number) = (1..number).reduce(1, :*)
  end
end
