module Example
  ## Common string transformations and queries.
  class StringUtils
    def reverse(str) = str.reverse
    def upcase(str) = str.upcase
    def words(str) = str.split(/\s+/)
    def palindrome?(str) = str == str.reverse
    def char_count(str) = str.length
  end
end
