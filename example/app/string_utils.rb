module Example
  class StringUtils
    def reverse(s) = s.reverse
    def upcase(s) = s.upcase
    def words(s) = s.split(/\s+/)
    def palindrome?(s) = s == s.reverse
    def char_count(s) = s.length
  end
end
