require "test_helper"

class TestErrors < Minitest::Test
  def test_base_error_inherits_from_standard_error
    assert_operator Minitest::JRuby::Server::Error, :<, StandardError
  end

  def test_server_not_running
    assert_operator Minitest::JRuby::Server::ServerNotRunning, :<, Minitest::JRuby::Server::Error
  end

  def test_connection_error
    assert_operator Minitest::JRuby::Server::ConnectionError, :<, Minitest::JRuby::Server::Error
  end

  def test_invalid_filter
    assert_operator Minitest::JRuby::Server::InvalidFilter, :<, Minitest::JRuby::Server::Error
  end

  def test_server_already_running
    assert_operator Minitest::JRuby::Server::ServerAlreadyRunning, :<, Minitest::JRuby::Server::Error
  end

  def test_no_tests_found
    assert_operator Minitest::JRuby::Server::NoTestsFound, :<, Minitest::JRuby::Server::Error
  end
end
