require "drb"

module Minitest
  module JRubyServer
    class Client
      def initialize(config: Config.new)
        @config = config
        @remote = nil
      end

      def connect
        unless File.exist?(@config.uri_file)
          raise ServerNotRunning,
            "No server found at #{@config.uri_file}. Start one with: mt-server"
        end

        uri = File.read(@config.uri_file).strip
        begin
          DRb.current_server
        rescue DRb::DRbServerNotFound
          DRb.start_service
        end
        @remote = DRbObject.new_with_uri(uri)

        @remote.ping
        self
      rescue DRb::DRbConnError => e
        raise ConnectionError,
          "Server at #{uri} is not responding: #{e.message}"
      end

      def connected?
        !@remote.nil?
      end

      def run_tests(seed: nil, include_filter: nil, exclude_filter: nil)
        ensure_connected!
        @remote.run_tests(seed: seed, include_filter: include_filter,
                          exclude_filter: exclude_filter)
      rescue DRb::DRbConnError => e
        raise ConnectionError, "Lost connection to server: #{e.message}"
      end

      def info
        ensure_connected!
        @remote.info
      rescue DRb::DRbConnError => e
        raise ConnectionError, "Lost connection to server: #{e.message}"
      end

      def shutdown_server
        ensure_connected!
        @remote.shutdown
      rescue DRb::DRbConnError
        :ok
      end

      private

      def ensure_connected!
        raise ServerNotRunning, "Not connected. Call #connect first." unless connected?
      end
    end
  end
end
