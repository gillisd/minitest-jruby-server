module Minitest
  module Jruby
    module Server
      class ResultFormatter
        def initialize(io: $stdout)
          @io = io
        end

        def print_server_info(info)
          @io.puts "Connected to test daemon"
          @io.puts "  Engine:  #{info[:engine]}"
          @io.puts "  PID:     #{info[:pid]}"
          @io.puts "  Uptime:  #{format_duration(info[:uptime])}"
          @io.puts "  Runs:    #{info[:runs_so_far]}"
          @io.puts
        end

        def print_run_result(result)
          status = result[:passed] ? "PASS" : "FAIL"
          @io.puts format("Run #%-3d %s  %d tests, %d assertions, %d failures, %d errors in %.4fs", result[:run],
                          status, result[:tests], result[:assertions], result[:failures], result[:errors], result[:time])
        end

        def print_summary(times:, runs:)
          @io.puts
          @io.puts "  Fastest: %.4fs" % times.min
          @io.puts "  Slowest: %.4fs" % times.max
          @io.puts "  Median:  %.4fs" % times.sort[times.size / 2]
          @io.puts format("  Mean:    %.4fs", times.sum / times.size)

          return unless times.size >= 6

          first3 = times.first(3).sum / 3
          last3  = times.last(3).sum / 3
          delta  = ((last3 - first3) / first3 * 100)
          direction = delta.negative? ? "faster" : "slower"
          @io.puts format("  Trend:   last 3 runs %.1f%% %s than first 3", delta.abs, direction)
        end

        private

        def format_duration(seconds)
          if seconds < 60
            "%.1fs" % seconds
          elsif seconds < 3600
            format("%dm %ds", seconds / 60, seconds % 60)
          else
            format("%dh %dm", seconds / 3600, (seconds % 3600) / 60)
          end
        end
      end
    end
  end
end
