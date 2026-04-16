module Minitest
  module JRuby
    module Server
      ## Formats test-run results and server info for human-readable
      ## terminal output.
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
          @io.puts format(
            "Run #%<run>-3d %<status>s  %<tests>d tests, %<assertions>d assertions, " \
            "%<failures>d failures, %<errors>d errors in %<time>.4fs",
            run: result[:run], status: status, tests: result[:tests],
            assertions: result[:assertions], failures: result[:failures],
            errors: result[:errors], time: result[:time]
          )
        end

        def print_summary(times:)
          @io.puts
          print_timing_stats(times)

          return unless times.size >= 6

          print_warmup_trend(times)
        end

        private

        def print_timing_stats(times)
          @io.puts format("  Fastest: %<time>.4fs", time: times.min)
          @io.puts format("  Slowest: %<time>.4fs", time: times.max)
          @io.puts format("  Median:  %<time>.4fs", time: times.sort[times.size / 2])
          @io.puts format("  Mean:    %<time>.4fs", time: times.sum / times.size)
        end

        def print_warmup_trend(times)
          first3 = times.first(3).sum / 3
          last3  = times.last(3).sum / 3
          delta  = ((last3 - first3) / first3 * 100)
          direction = delta.negative? ? "faster" : "slower"
          @io.puts format("  Trend:   last 3 runs %<delta>.1f%% %<direction>s than first 3",
                          delta: delta.abs, direction: direction)
        end

        def format_duration(seconds)
          if seconds < 60
            format("%<seconds>.1fs", seconds: seconds)
          elsif seconds < 3600
            format("%<minutes>dm %<seconds>ds", minutes: seconds / 60, seconds: seconds % 60)
          else
            format("%<hours>dh %<minutes>dm", hours: seconds / 3600, minutes: (seconds % 3600) / 60)
          end
        end
      end
    end
  end
end
