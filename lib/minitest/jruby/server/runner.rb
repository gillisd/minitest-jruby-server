require "minitest"
require "stringio"

module Minitest
  module JRuby
    module Server
      ## Executes Minitest suites in-process and returns a result hash
      ## with counts, timing, and captured output.
      class Runner
        def run(seed: nil, include_filter: nil, exclude_filter: nil)
          seed ||= Random.new_seed % 0xFFFF

          validate_filter!(include_filter)
          validate_filter!(exclude_filter)

          options = build_options(seed, include_filter, exclude_filter)
          reporter, elapsed = execute_suite(options)
          collect_results(reporter, seed, elapsed, options[:io])
        end

        private

        def build_options(seed, include_filter, exclude_filter)
          opts = { io: StringIO.new, seed: seed }
          opts[:include] = include_filter if include_filter
          opts[:exclude] = exclude_filter if exclude_filter
          opts
        end

        def execute_suite(options)
          Minitest.seed = options[:seed]
          srand options[:seed]

          reporter = Minitest::CompositeReporter.new
          reporter << Minitest::SummaryReporter.new(options[:io], options)
          reporter.start

          t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          Minitest.run_all_suites reporter, options
          elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0

          reporter.report
          [reporter, elapsed]
        end

        def collect_results(reporter, seed, elapsed, io)
          summary = reporter.reporters.grep(Minitest::SummaryReporter).first

          {
            seed: seed,
            tests: summary.count,
            assertions: summary.assertions,
            failures: summary.failures,
            errors: summary.errors,
            skips: summary.skips,
            passed: summary.passed?,
            time: elapsed,
            output: io.string,
          }
        end

        def validate_filter!(pattern)
          return unless pattern
          return unless pattern.is_a?(String) && pattern =~ %r{^/(.*)/[mixo]*$}

          Regexp.new(::Regexp.last_match(1))
        rescue RegexpError => e
          raise InvalidFilter, "Invalid filter pattern: #{pattern} (#{e.message})"
        end
      end
    end
  end
end
