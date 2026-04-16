require "drb"

module Minitest
  module JRuby
    module Server
      ## DRb server that exposes a Daemon instance over a Unix socket,
      ## handling lifecycle, signal traps, and stale-PID detection.
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

          DRb.thread&.join
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
          pid = extract_pid_from_uri(old_uri)
          return unless pid

          verify_pid_not_running!(pid)
        end

        def verify_pid_not_running!(pid)
          Process.kill(0, pid)
          raise ServerAlreadyRunning,
                "Server already running (PID #{pid}). URI file: #{@config.uri_file}"
        rescue Errno::ESRCH
          File.delete(@config.uri_file) # stale file, remove it
        rescue Errno::EPERM
          raise ServerAlreadyRunning,
                "Server already running (PID #{pid}, not owned by this user)"
        end

        def extract_pid_from_uri(uri_string)
          return unless uri_string =~ /\.(\d+)$/

          ::Regexp.last_match(1).to_i
        end

        def cleanup
          FileUtils.rm_f(@config.uri_file)
        end

        def install_signal_handlers
          %w[INT TERM].each do |sig|
            trap(sig) do
              warn "\n[mt-server] Shutting down..."
              stop
              exit
            end
          end
        end
      end
    end
  end
end
