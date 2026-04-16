require "English"
require "tmpdir"

module Minitest
  module JRuby
    module Server
      ## Holds configuration for both mt-server and mt-client,
      ## including paths, socket locations, and timeouts.
      class Config
        attr_reader :project_root, :uri_file, :socket_dir,
                    :test_paths, :load_paths

        attr_writer :connect_timeout

        def initialize(project_root: Dir.pwd, uri_file: nil, socket_dir: Dir.tmpdir,
                       test_paths: nil, load_paths: nil)
          @project_root    = project_root
          @uri_file        = uri_file || File.join(project_root, ".minitest-jruby.uri")
          @socket_dir      = socket_dir
          @test_paths      = test_paths || ["test/**/*_test.rb", "test/**/test_*.rb"]
          @load_paths      = load_paths || ["lib", "test"]
          @connect_timeout = nil
        end

        def connect_timeout
          @connect_timeout || 5
        end

        def socket_path
          File.join(socket_dir, "minitest_jruby.#{$PROCESS_ID}")
        end

        def uri
          "drbunix:#{socket_path}"
        end
      end
    end
  end
end
