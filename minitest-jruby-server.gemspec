require_relative "lib/minitest/jruby_server/version"

Gem::Specification.new do |s|
  s.name        = "minitest-jruby-server"
  s.version     = Minitest::JRubyServer::VERSION
  s.authors     = ["Minitest JRuby Contributors"]
  s.summary     = "Persistent JRuby test daemon for Minitest v6"
  s.description = "Boot JRuby once, run Minitest suites on demand via DRb. " \
                  "CRuby clients trigger runs; the JVM JIT warms up over successive runs."
  s.license     = "MIT"
  s.required_ruby_version = ">= 3.1"

  s.files       = Dir["lib/**/*.rb", "bin/*", "README.md", "LICENSE.txt"]
  s.bindir      = "bin"
  s.executables = ["mt-server", "mt-client"]

  s.add_dependency "minitest", "~> 6.0"
  s.add_dependency "drb",      "~> 2.0"
end
