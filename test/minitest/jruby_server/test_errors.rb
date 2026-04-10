require "test_helper"

class TestErrors < Minitest::Test
  def test_base_error_inherits_from_standard_error
    assert_operator Minitest::JRubyServer::Error, :<, StandardError
  end

  def test_server_not_running
    assert_operator Minitest::JRubyServer::ServerNotRunning, :<, Minitest::JRubyServer::Error
  end

  def test_connection_error
    assert_operator Minitest::JRubyServer::ConnectionError, :<, Minitest::JRubyServer::Error
  end

  def test_invalid_filter
    assert_operator Minitest::JRubyServer::InvalidFilter, :<, Minitest::JRubyServer::Error
  end

  def test_server_already_running
    assert_operator Minitest::JRubyServer::ServerAlreadyRunning, :<, Minitest::JRubyServer::Error
  end

  def test_no_tests_found
    assert_operator Minitest::JRubyServer::NoTestsFound, :<, Minitest::JRubyServer::Error
  end
end
