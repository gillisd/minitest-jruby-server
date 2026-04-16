require "English"
module Minitest
  module JRuby
    module Server
      class Daemon
        def initialize(runner: Runner.new)
          @runner     = runner
          @run_count  = 0
          @mutex      = Mutex.new
          @started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        end

        def run_tests(seed: nil, include_filter: nil, exclude_filter: nil)
          @mutex.synchronize do
            @run_count += 1
            result = @runner.run(seed: seed, include_filter: include_filter,
                                 exclude_filter: exclude_filter)
            result.merge(run: @run_count, engine: engine_string)
          end
        end

        def info
          {
            engine: engine_string,
            pid: $PROCESS_ID,
            runs_so_far: @run_count,
            uptime: Process.clock_gettime(Process::CLOCK_MONOTONIC) - @started_at,
          }
        end

        def ping
          :pong
        end

        def shutdown
          Thread.new { DRb.stop_service }
          :ok
        end

        private

        def engine_string
          "#{RUBY_ENGINE} #{RUBY_ENGINE_VERSION}"
        end
      end
    end
  end
end
