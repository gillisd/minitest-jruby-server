require "drb"

module Minitest
  module JRubyServer
    class Server
      def initialize(daemon:, config: Config.new)
        @daemon = daemon
        @config = config
        @started = false
      end

      def start
        check_not_already_running!

        DRb.start_service @config.uri, @daemon
        @started = true
        File.write @config.uri_file, @config.uri

        install_signal_handlers
        at_exit { cleanup }

        DRb.thread.join
      end

      def stop
        cleanup
        DRb.stop_service if @started
        @started = false
      end

      def uri
        @config.uri
      end

      private

      def check_not_already_running!
        return unless File.exist?(@config.uri_file)

        old_uri = File.read(@config.uri_file).strip
        if old_uri =~ /\.(\d+)$/
          pid = $1.to_i
          begin
            Process.kill(0, pid)
            raise ServerAlreadyRunning,
              "Server already running (PID #{pid}). URI file: #{@config.uri_file}"
          rescue Errno::ESRCH
            File.delete(@config.uri_file) # stale file, remove it
          rescue Errno::EPERM
            raise ServerAlreadyRunning,
              "Server already running (PID #{pid}, not owned by this user)"
          end
        end
      end

      def cleanup
        File.delete(@config.uri_file) if File.exist?(@config.uri_file)
      end

      def install_signal_handlers
        %w[INT TERM].each do |sig|
          trap(sig) do
            $stderr.puts "\n[mt-server] Shutting down..."
            stop
            exit
          end
        end
      end
    end
  end
end
