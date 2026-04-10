module Minitest
  module JRubyServer
    class TestLoader
      def initialize(config:)
        @config = config
      end

      def test_files
        @config.test_paths.flat_map { |pattern|
          Dir.glob(File.join(@config.project_root, pattern))
        }.uniq.sort
      end

      def setup_load_path!
        @config.load_paths.each do |path|
          full = File.join(@config.project_root, path)
          $LOAD_PATH.unshift(full) unless $LOAD_PATH.include?(full)
        end
      end

      def load_tests!
        files = test_files
        if files.empty?
          raise NoTestsFound,
            "No test files found matching: #{@config.test_paths.join(", ")} " \
            "in #{@config.project_root}"
        end

        files.each { |f| require f }
      end

      def loaded_suites
        Minitest::Runnable.runnables.reject { |r| r == Minitest::Test }
      end
    end
  end
end
