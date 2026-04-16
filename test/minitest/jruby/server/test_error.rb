require "test_helper"

class TestErrors < Minitest::Test
  def test_base_error_inherits_from_standard_error
    assert_operator Minitest::Jruby::Server::Error, :<, StandardError
  end

  def test_server_not_running
    assert_operator Minitest::Jruby::Server::ServerNotRunning, :<, Minitest::Jruby::Server::Error
  end

  def test_connection_error
    assert_operator Minitest::Jruby::Server::ConnectionError, :<, Minitest::Jruby::Server::Error
  end

  def test_invalid_filter
    assert_operator Minitest::Jruby::Server::InvalidFilter, :<, Minitest::Jruby::Server::Error
  end

  def test_server_already_running
    assert_operator Minitest::Jruby::Server::ServerAlreadyRunning, :<, Minitest::Jruby::Server::Error
  end

  def test_no_tests_found
    assert_operator Minitest::Jruby::Server::NoTestsFound, :<, Minitest::Jruby::Server::Error
  end
end
