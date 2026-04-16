require "test_helper"
require "string_utils"

## Tests for Example::StringUtils transformations.
class StringUtilsTest < Minitest::Test
  def setup
    @utils = Example::StringUtils.new
  end

  def test_reverse
    assert_equal "olleh", @utils.reverse("hello")
  end

  def test_upcase
    assert_equal "HELLO", @utils.upcase("hello")
  end

  def test_words
    assert_equal %w[the quick fox], @utils.words("the quick fox")
  end

  def test_palindrome
    assert @utils.palindrome?("racecar")
    refute @utils.palindrome?("hello")
  end

  def test_char_count
    assert_equal 5, @utils.char_count("hello")
  end
end
