require "minitest"
require "stringio"

module Minitest
  module Jruby
    module Server
      class Runner
        def run(seed: nil, include_filter: nil, exclude_filter: nil)
          seed ||= Random.new_seed % 0xFFFF

          validate_filter!(include_filter)
          validate_filter!(exclude_filter)

          options = { io: StringIO.new, seed: seed }
          options[:include] = include_filter if include_filter
          options[:exclude] = exclude_filter if exclude_filter

          Minitest.seed = seed
          srand seed

          reporter = Minitest::CompositeReporter.new
          reporter << Minitest::SummaryReporter.new(options[:io], options)
          reporter.start

          t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          Minitest.run_all_suites reporter, options
          elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0

          reporter.report

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
            output: options[:io].string,
          }
        end

        private

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
