require "zeitwerk"

module Minitest
  module Jruby
    module Server
      LOADER = Zeitwerk::Loader.new
      LOADER.tag = "minitest-jruby-server"
      LOADER.inflector = Zeitwerk::GemInflector.new(__FILE__)
      LOADER.push_dir("#{__dir__}/server", namespace: Minitest::Jruby::Server)
      LOADER.setup
    end
  end
end
