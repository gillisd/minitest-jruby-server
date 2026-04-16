require "zeitwerk"

module Minitest
  module JRuby
    module Server
      LOADER = Zeitwerk::Loader.new
      LOADER.tag = "minitest-jruby-server"
      LOADER.inflector = Zeitwerk::GemInflector.new(__FILE__)
      LOADER.inflector.inflect("jruby" => "JRuby")
      LOADER.push_dir("#{__dir__}/server", namespace: Minitest::JRuby::Server)
      LOADER.setup

      require_relative "server/error" # eager-load error hierarchy (subclasses share one file)
    end
  end
end
