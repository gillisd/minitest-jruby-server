module Minitest
  module JRubyServer
    class Error < StandardError; end
    class ServerNotRunning < Error; end
    class ConnectionError < Error; end
    class InvalidFilter < Error; end
    class ServerAlreadyRunning < Error; end
    class NoTestsFound < Error; end
  end
end
